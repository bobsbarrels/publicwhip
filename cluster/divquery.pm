# $Id: divquery.pm,v 1.1 2004/01/17 18:53:51 frabcus Exp $
# This extracts a distance metric for a set of divisions, and is able to write
# it out in a format for loading into GNU Ooctave (or MatLab)

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package divquery;
use strict;

sub get_div_ixs
{
    my $dbh = shift; 
    my $where = shift;
    my $limit = shift;

    my $sth = db::query($dbh, "select pw_division.division_id from pw_division, pw_cache_divinfo where
        pw_division.division_id = pw_cache_divinfo.division_id and $where 
        order by pw_division.division_date desc, pw_division.division_number desc $limit");
    my @div_ixs;
    while (my @data = $sth->fetchrow_array())
    {
        push @div_ixs, $data[0];
    }
    return \@div_ixs;
}

sub rebel_distance_metric
{
    my $dbh = shift;
    my $div_ixs = shift;
    my $clause = shift;

    # Count MPs
    my $sth = db::query($dbh, "select pw_mp.mp_id from pw_mp, pw_cache_mpinfo where pw_mp.mp_id = pw_cache_mpinfo.mp_id and $clause");
    print $sth->rows . " mps\n";
    my @mp_ixs;
    while (my @data = $sth->fetchrow_array())
    {
        push @mp_ixs, $data[0];
    }

    # Read all votes in, and make array of MPs and whether rebel in each division
    my $limit = " and (pw_vote.mp_id = " . join(" or pw_vote.mp_id = ", @mp_ixs) . ")";
    $limit .= " and (pw_vote.division_id = " . join(" or pw_vote.division_id = ", @$div_ixs) . ")";
    $sth = db::query($dbh, "select pw_vote.division_id, pw_vote.mp_id, vote, whip_guess from " .
        "pw_cache_whip, pw_vote, pw_mp where " .
        "pw_cache_whip.division_id = pw_vote.division_id and " . 
        "pw_mp.mp_id = pw_vote.mp_id and " .
        "pw_mp.party = pw_cache_whip.party " . 
        "$limit");
    print $sth->rows . " votes\n";
    my @votematrix;
    while (my @data = $sth->fetchrow_array())
    {
        my ($div_dat, $mp_dat, $vote, $whip) = @data;
        $vote =~ s/tell//;
        $whip =~ s/tell//;
        my $votescore = undef;
        if ($vote eq "both")
        { 
            $votescore = 0;
        }
        else
        {
            $votescore = 1 if ($vote eq $whip); # loyal
            $votescore = -1 if ($vote ne $whip); # rebel
        }
        die "Unexpected $vote voted" if (!defined $votescore);

        my $curvalue = $votematrix[$mp_dat][$div_dat];
        if ((defined $curvalue) && ($curvalue != $votescore))
        {
            print "Clash: curvalue " . $curvalue . " votescore " . $votescore;
        }
        $votematrix[$mp_dat][$div_dat] += $votescore;
    }

    # Create matrix of "distances" between divisions
    my @metricD;
    for my $div_1 (@$div_ixs)
    {
        for my $div_2 (@$div_ixs)
        {
            # Only do half triangle
            next if $div_1 > $div_2;

            # For the pair of divs, tot up which MPs rebelled same in
            my $mps_both_in = 0;
            my $mps_voted_same = 0;
            my $mps_both_rebel = 0;
            for my $mp_ix (@mp_ixs)
            {
                my $vote1 = $votematrix[$mp_ix][$div_1];
                my $vote2 = $votematrix[$mp_ix][$div_2];
                $vote1 = 0 if (!defined $vote1);
                $vote2 = 0 if (!defined $vote2);
#                if ($vote1 != 0 and $vote2 != 0)
#                {
#                    $mps_both_in++;
#                    if ($vote1 == $vote2)
#                    {
#                        $mps_voted_same++;
#                    }
#                }
                if ($vote1 < 0 and $vote2 < 0)
                {
                    $mps_both_rebel++;
                }
            } 

            # Create score based on this
            if ($mps_both_rebel != 0)
            {
                $metricD[$div_1][$div_2] = 1/($mps_both_rebel + 1); #($mps_both_in - $mps_voted_same) / $mps_both_in;
            }
            elsif ($div_1 == $div_2)
            {
                $metricD[$div_1][$div_2] = 0;
            }
            else
            {
                $metricD[$div_1][$div_2] = 1;
            }
        }
    }

    return \@metricD;
}

# TODO: Update
sub octave_writer
{
    my $fh = shift;
    my $dbh = shift;
    my $mp_ixs = shift;
    my $metricD = shift;

    use POSIX qw(strftime);
    my $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
    print $fh "# Autogenerated by mpquery::octave_writer from The Public Whip project on $now_string\n\n";

    # Print it all out
    for my $mp_1 (@$mp_ixs)
    {
        my $sthmp = db::query($dbh, "select last_name, first_name, party from pw_mp where mp_id=?", $mp_1);
        die "Wrong number of rows back" if $sthmp->rows != 1;
        my @data = $sthmp->fetchrow_array();
        my ($lastname, $firstname, $party) = @data; 

        print $fh "na" . $mp_1 . " = \"" . $lastname . ", " . $firstname . "\";\n";
        print $fh "pa" . $mp_1 . " = \"" . $party . "\";\n";
        print $fh "r" . $mp_1 . " = [";
        for my $mp_2 (@$mp_ixs)
        {
            print $fh "," if ($mp_2 != $$mp_ixs[0]);
            if ($mp_1 <= $mp_2)
            {
                print $fh $$metricD[$mp_1][$mp_2];
            }
            else
            {
                print $fh $$metricD[$mp_2][$mp_1];
            }
        }
        print $fh "];\n";
    }

    print $fh "D=[\n";
    foreach my $mp_ix (@$mp_ixs)
    {
        print $fh "r" . $mp_ix . ";";
    }
    print $fh "];\n";

    print $fh "ns=[\n";
    for my $mp_ix (@$mp_ixs)
    {
        print $fh "na" . $mp_ix . ";";
    }
    print $fh "];\n";

    print $fh "ps=[\n";
    for my $mp_ix (@$mp_ixs)
    {
        print $fh "pa" . $mp_ix . ";";
    }
    print $fh "];\n";
}

1;
