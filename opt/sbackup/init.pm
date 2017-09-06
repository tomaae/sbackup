package init;

###########################################################################################
#
#                                         sbackup
#                                         init
#
###########################################################################################

use strict;
use warnings;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(
									get_env f_arguments
									$slash $BINPATH $MODULESPATH $ETCPATH $JOBCONFIGPATH $VARPATH $SESSIONLOGPATH $RUNFILEPATH
									$cmd_ls $cmd_ln $cmd_rm $cmd_sleep $cmd_cp $cmd_mv $cmd_mkdir $cmd_chmod $cmd_rsync
							  );



sub get_env{
	#&f_output("DEBUG","Setting required parameters.");
	our $slash="/";
	
	our $BINPATH        = "/opt/sbackup/";
	our $MODULESPATH    = "/opt/sbackup/modules/";
	our $ETCPATH        = "/etc/sbackup/";
	our $JOBCONFIGPATH  = "/etc/sbackup/jobs/";
	our $VARPATH        = "/var/log/sbackup/";
	our $SESSIONLOGPATH = "/var/log/sbackup/sessionlogs/";
	our $RUNFILEPATH    = "/var/log/sbackup/run/";

	our $cmd_ls         = "ls -l";
	our $cmd_ln         = "ln -s";
	our $cmd_rm         = "rm -r";
	our $cmd_sleep      = "sleep";
	our $cmd_cp         = "cp";
	our $cmd_mv         = "mv";
	our $cmd_mkdir      = "mkdir -p";
	our $cmd_chmod      = "chmod";
	our $cmd_rsync      = "rsync";
	
	#&f_output("DEBUG","Required parameters set.");
}

##
##LEVENSHTEIN
##
sub f_levenshtein {
	use List::Util qw(min);
	my ($str1, $str2) = @_;
	my @ar1 = split //, $str1;
	my @ar2 = split //, $str2;

	my @dist;
	$dist[$_][0] = $_ foreach (0 .. @ar1);
	$dist[0][$_] = $_ foreach (0 .. @ar2);

	foreach my $i (1 .. @ar1){
		foreach my $j (1 .. @ar2){
			my $cost = $ar1[$i - 1] eq $ar2[$j - 1] ? 0 : 1;
			$dist[$i][$j] = min(
			$dist[$i - 1][$j] + 1,
			$dist[$i][$j - 1] + 1,
			$dist[$i - 1][$j - 1] + $cost );
		}
	}
	return $dist[@ar1][@ar2];
}

##
##ARGUMENT HANDLER
##
sub f_arguments {
	my $arguments = shift;
  my $noofarguments = @ARGV;
  if($noofarguments eq "0"){&f_help(\%{$arguments});}
  my @val;
  
  sub f_help { #HELP FUNCTION
  	my $arguments = shift;
    print "Syntax:\n\n";
    my @arguments_sort = sort { ${$arguments}{$a}{help_display} <=> ${$arguments}{$b}{help_display} } keys %{$arguments};
    for my $tmp(@arguments_sort){
    	if(defined ${$arguments}{$tmp}{help_header} && ${$arguments}{$tmp}{help_display} > 0){
     		print "  ${$arguments}{$tmp}{help_header}\n";
    		print "\t${$arguments}{$tmp}{help_args}\n\n";
    	}
    }
    exit 1;
    return 1;
  }
  
  ##Parse all arguments
  while (@ARGV){
  	my $arg = shift @ARGV;
  	
  	if ($arg =~ /^\-(.*)$/){
  		my $arg_s = $1;
  		
  		##Check aliases
  		if(!defined ${$arguments}{$arg_s}){
    		for my $tmp(keys %{$arguments}){
    			next if !defined ${$arguments}{$tmp}{aliases};
    			@val = split /;/, ${$arguments}{$tmp}{aliases};
    			for my $tmp2(@val){
    				$arg_s = $tmp if $arg_s eq $tmp2;
    			}
    		}
  		}
  		
  		##Try to resolve incomplete/mistyped argument
  		if(!defined ${$arguments}{$arg_s}){
  			##Compare to all arguments and get number of possibilities
  			my $possible_no = 0;
  			my $possible_last = "";
  			for my $tmp(sort keys %{$arguments}){
  				if($tmp =~ /^$arg_s/){
  					$possible_no++;
  					$possible_last = $tmp;
  				}
  			}
  
  			##Error on multiple possibilities with shortened argument
  			if($possible_no > 1){
  				if(int(length($arg_s)) == 0){&f_help($arguments);}
  				print "\nSyntax error.\nShortened argument \"$arg\" have multiple possibilities:\n\n";
  				for my $tmp(sort keys %{$arguments}){
  					if($tmp =~ /^$arg_s/ && defined ${$arguments}{$tmp}{help_header}){
  						print "  ${$arguments}{$tmp}{help_header}\n";
    					print "\t${$arguments}{$tmp}{help_args}\n\n";
    				}
  				}
  				print "\n";exit 1;
  			}
  			
  			##Try to detect a typo
  			my $most_likely = "";
  			if($possible_no == 0){
  				##Use levenshtein to find typo matches
  				my %arguments_matched = ();
  				for my $tmp(keys %{$arguments}){
  					$arguments_matched{$tmp} = &f_levenshtein($arg_s,$tmp);
  					$arguments_matched{$tmp} = &f_levenshtein($arg_s,substr($tmp,0,length($arg_s))) if length($arg_s) < length($tmp) && $arguments_matched{$tmp} > &f_levenshtein($arg_s,substr($tmp,0,length($arg_s)));
  				}
  				
  				##Get most likely match for typo
  				for my $tmp(keys %arguments_matched){
  					##Discard unlikely matches
  					if(int(length($tmp) / 2) < $arguments_matched{$tmp} || int(length($arg_s) / 2) < $arguments_matched{$tmp}){
  						delete $arguments_matched{$tmp};
  						next;
  					}
  					$most_likely = $tmp if $most_likely eq "" || $arguments_matched{$tmp} < $arguments_matched{$most_likely};
  				}
  				
  				##Discard most likely match if next match is too close
  				if($most_likely ne ""){
    				for my $tmp(keys %arguments_matched){
    					next if $most_likely eq $tmp;
    					$most_likely = "" if (int($arguments_matched{$most_likely}) + 2 ) > int ($arguments_matched{$tmp});
    				}
  				}
  				
  				if($most_likely ne ""){
  					if(int $arguments_matched{$most_likely} > 2){
  						##Error on heavy typo
  						print "\nSyntax error.\nMistyped argument \"$arg\", probable argument \"-".$most_likely."\"\n";
  						print "  ${$arguments}{$most_likely}{help_header}\n";
    					print "\t${$arguments}{$most_likely}{help_args}\n\n";
  						exit 1;
  					}else{
  						##Fix typo on single match
  						$possible_no = 1;
  						$arg_s = $most_likely;
  						$arg = "-".$most_likely;
  					}
  				}elsif(int(keys %arguments_matched) > 0){
  					##Error on more possible matches
    				print "\nSyntax error.\nMistyped argument \"$arg\" have multiple possibilities:\n\n";
    				for my $tmp(sort keys %arguments_matched){
    					print "  ${$arguments}{$tmp}{help_header}\n";
    					print "\t${$arguments}{$tmp}{help_args}\n\n";
    				}
    				print "\n";exit 1;
  				}else{
  					print "\nSyntax error.\nUnknown argument \"$arg\".\n\n";&f_help($arguments);
  				}
  			}
  			
  			##Set arg when only one possibility is found
  			if($possible_no == 1){
  				if($most_likely eq ""){
  					$arg_s = $possible_last;
  					$arg = "-".$possible_last;
  				}
  			}else{
  				print "\nSyntax error.\nUnknown argument \"$arg\".\n\n";&f_help($arguments);
  			}
  		}
  		
  		##Set Argument
  		${${$arguments}{$arg_s}{var}} = 1;
  		  				
  		##Get argument values
  		my $vals_no = 0;
  		while($ARGV[0] && $ARGV[0] !~ /^-/){
  			##Argument does not support values
  			if(!defined ${$arguments}{$arg_s}{val1}){
  				print "\nSyntax error.\nArgument \"$arg\" does not support values.\n\n";
  				print "  ${$arguments}{$arg_s}{help_header}\n";
    			print "\t${$arguments}{$arg_s}{help_args}\n\n";
  				exit 1;
  			}
  			$vals_no++;
  			##Too many values for specified argument
  			if(!defined ${$arguments}{$arg_s}{"val".$vals_no}){
  				print "\nSyntax error.\nToo many values for argument \"$arg\".\n\n";
  				print "  ${$arguments}{$arg_s}{help_header}\n";
    			print "\t${$arguments}{$arg_s}{help_args}\n\n";
  				exit 1;
  			}
  			my $param = shift @ARGV;
  			${${$arguments}{$arg_s}{"val".$vals_no}} = $param;
  		}
  		
  		##Missing value for specified argument
  		if(${$arguments}{$arg_s}{vals_mandatory} == 1 && defined ${$arguments}{$arg_s}{"val".($vals_no + 1)}){
  			print "\nSyntax error.\nArgument \"$arg\" is missing mandatory values.\n\n";
  			print "  ${$arguments}{$arg_s}{help_header}\n";
    		print "\t${$arguments}{$arg_s}{help_args}\n\n";
  			exit 1;
  		}
  	}else{
  		##Invalid argument entry
  		print "\nSyntax error.\nInvalid argument \"$arg\".\n\n";&f_help($arguments);
  	}
  }
  
  ##Check for argument dependency
  my $args_no = 0;
  for my $arg_s(sort keys %{$arguments}){
  	next if !defined ${${$arguments}{$arg_s}{var}};
  	next if defined ${${$arguments}{$arg_s}{var}} && ${${$arguments}{$arg_s}{var}} != 1;
  	$args_no++ if defined ${$arguments}{$arg_s}{primary} && ${$arguments}{$arg_s}{primary} == 1;
  	next if !defined ${$arguments}{$arg_s}{dependency};
  	next if defined ${$arguments}{$arg_s}{dependency} && ${$arguments}{$arg_s}{dependency} eq "";
  	
  	@val = split /;/,${$arguments}{$arg_s}{dependency};
  	my $dependency_ok = 0;
  	for my $tmp(@val){
  		$dependency_ok = 1 if defined ${${$arguments}{$tmp}{var}} && ${${$arguments}{$tmp}{var}} == 1;
  	}
  	if($dependency_ok == 0){
  		print "\nSyntax error.\nArgument \"-$arg_s\" is not usable in this combination.\n\n";exit 1;
  	}
  }
  
  if($args_no > 1){
  	my @mixed_args;
  	for my $arg_s(sort keys %{$arguments}){
  		push @mixed_args,"-".$arg_s if ${$arguments}{$arg_s}{primary} && ${${$arguments}{$arg_s}{var}};
  	}
  	print "\nSyntax error.\nArguments ".join(", ",@mixed_args)." cannot be used together.\n\n";exit 1;
  }
} 

1;