# This is a template for creating your own logfile parser. You can also look
# in the other .pm files in this directory as good examples.

package Pisg::Parser::Format::pircbot;

use strict;
$^W = 1;

# The 3 variables in the new subrountine, 'normalline', 'actionline' and
# 'thirdline' represents regular expressions for extracting information from
# the logfile. normalline is for lines where the person merely said
# something, actionline is for lines where the person performed an action,
# and thirdline matches everything else, including things like kicks, nick
# changes, and op grants.  See the thirdline subroutine for a list of
# everything it should match.

sub new
{
    my ($type, %args) = @_;
    my $ctcpchr = chr(1);

    my $self = {
        cfg => $args{cfg},
        normalline => '^(\d+)\s:([^!]+)!([^@]+)@(\S+)\sPRIVMSG\s(#\S+)\s:([^' . $ctcpchr . '].*)$',
        actionline => '^(\d+)\s:([^!]+)!([^@]+)@(\S+)\sPRIVMSG\s(#\S+)\s:' . $ctcpchr . 'ACTION (.+)' . $ctcpchr . '\s*$',
	thirdline  => '^(\d+)\s:([^!]+)!([^@]+)@(\S+)\s(.+)$',
    };

    bless($self, $type);
    return $self;
}

# Parse a normal line - returns a hash with 'hour', 'nick' and 'saying'
sub normalline
{
    my ($self, $line, $lines) = @_;
    my %hash;

    if ($line =~ /$self->{normalline}/o) {
print "$line\n";

        # Most log formats are regular enough that you can just match the
        # appropriate things with parentheses in the regular expression.

        my @time = localtime($1 / 1000);
        $hash{hour}   = $time[2];
        $hash{nick}   = $2;
        $hash{saying} = $6;

        return \%hash;
    } else {
        return;
    }
}

# Parse an action line - returns a hash with 'hour', 'nick' and 'saying'
sub actionline
{
    my ($self, $line, $lines) = @_;
    my %hash;

    if ($line =~ /$self->{actionline}/o) {

        # Most log formats are regular enough that you can just match the
        # appropriate things with parentheses in the regular expression.

        my @time = localtime($1 / 1000);
        $hash{hour}   = $time[2];
        $hash{nick}   = $2;
        $hash{saying} = $6;

        return \%hash;
    } else {
        return;
    }
}

# Parses the 'third' line - (the third line is everything else, like
# topic changes, mode changes, kicks, etc.)
# thirdline() has to return a hash with the following keys, for
# every format:
#   hour            - the hour we're in (for timestamp logging)
#   min             - the minute we're in (for timestamp logging)
#   nick            - the nick
#   kicker          - the nick which kicked somebody (if any)
#   newtopic        - the new topic (if any)
#   newmode         - deops or ops, must be '+o' or '-o', or '+ooo'
#   newjoin         - a new nick which has joined the channel
#   newnick         - a person has changed nick and this is the new nick
#
# The hash may also have a "repeated" key indicating the number of times
# the line was repeated. (Used by eggdrops log for example.)
sub thirdline
{
    my ($self, $line, $lines) = @_;
    my %hash;

    if ($line =~ /$self->{thirdline}/o) {

        my @time = localtime($1 / 1000);
        $hash{hour}   = $time[2];
        $hash{min}  = $time[1];
        $hash{nick} = $2;

        my @line = split(/\s+/, "$5");

        if ($line[0] eq 'KICK') {
            $hash{kicker} = $hash{nick};
            $hash{nick} = $line[2];

        } elsif ($line[0] eq 'TOPIC') {
            $hash{newtopic} = join(' ', @line[2..$#line]);
            $hash{newtopic} =~ s/^://;

        } elsif ($line[0] eq 'MODE') {
            $hash{newmode} = join(' ', @line[2..$#line]);

        } elsif ($line[0] eq 'JOIN') {
            $hash{newjoin} = $hash{nick};

        } elsif ($line[0] eq 'NICK') {
            $hash{newnick} = $line[1];
            $hash{newnick} =~ s/^://;
        }


        return \%hash;

    } else {
        return;
    }
}

1;
