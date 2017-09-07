package config;

###########################################################################################
#
#                                         sbackup
#                                         config
#
###########################################################################################

use strict;
use warnings;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(load_jobs_config parse_job_config);


my %job_definition = ( ##Default value, Mandatory, Type, Range of type
  'NAME' => ["",1,"",""],
#  'UUID' => ["",0,"",""],
  'ENABLED' => ["0",1,"bool",""],
  'SCHEDULE' => {
  	'-enabled' => ["0",0,"bool",""],
  	'-day' => ["",0,"day",""],
  	'-time' => ["",0,"time",""],
  },
  'SOURCE' => {
  	'-host' => ["",0,"",""],
  	'-omv' => ["",0,"",""],
  	'-tree' => ["",0,"",""],
  	'-protect' => ["",0,"number",""],
  	'-snapshot' => {
  		'-enabled' => ["0",0,"bool",""],
  		'-type' => ["",0,"list","lvm"],
  		'-size' => ["",0,"number",""],
  		'-fallback' => ["0",0,"bool",""],
  	}
  },
  'TARGET' => {
  	#'-host' => ["",0,"",""],
  	'-omv' => ["",0,"",""],
  	'-tree' => ["",0,"",""],
  },
  'POST' => {
  	'-job' => {
  		'-name' => ["",0,"",""],
  	},
  	'-autorestart' => ["0",0,"bool",""],
  }
);

##
## JOB HANDLING
##
sub copy_job {
	my ($job,$config)=@_;
	for my $tmp(keys %{$config}){
		if(ref ${$config}{$tmp} eq "HASH"){
			%{${$job}{$tmp}} = ();
			copy_job(${$job}{$tmp},${$config}{$tmp});
		}elsif(ref ${$config}{$tmp} eq "ARRAY"){
			${$job}{$tmp} = ${${$config}{$tmp}}[0];
		}else{
			print "Code error in job definition\n";
			return 1;
		}
	}
	return 0;
}

sub verify_job {
	my ($job,$config,$job_path,$error)=@_;
	$error = 0 if !$error;
	for my $tmp(keys %{$config}){
		if(ref ${$config}{$tmp} eq "HASH"){
			push @{$job_path}, $tmp;
			$error = verify_job(${$job}{$tmp},${$config}{$tmp},$job_path,$error);
			pop @{$job_path};
		}elsif(ref ${$config}{$tmp} eq "ARRAY"){
			##Mandatory parameter
			if(${${$config}{$tmp}}[1] eq "1"){
				if(${$job}{$tmp} eq ""){
					print "Missing mandatory parameter ".join(">",@{$job_path}).">$tmp\n";
					$error = 1;
				}
			}
			##Bool test
			if(defined ${$job}{$tmp} && ${${$config}{$tmp}}[2] eq "bool"){
  			if(${$job}{$tmp} =~ /^(0|1|no|yes)$/i){
  				${$job}{$tmp} = 0 if ${$job}{$tmp} =~ /^(0|no)$/i;
  				${$job}{$tmp} = 1 if ${$job}{$tmp} =~ /^(1|yes)$/i;
  			}else{
  				print "Invalid value for ".join(">",@{$job_path}).">$tmp: ${$job}{$tmp}\n";
  				$error = 1;
  			}
			}
			##Numeric test
			if(defined ${$job}{$tmp} && ${${$config}{$tmp}}[2] eq "number"){
  			if(${$job}{$tmp} !~ /^[0-9]*$/){
  				print "Invalid value for ".join(">",@{$job_path}).">$tmp: ${$job}{$tmp}\n";
  				$error = 1;
  			}
			}
			##List test
			if(defined ${$job}{$tmp} && ${${$config}{$tmp}}[2] eq "list"){
  			if(${$job}{$tmp} =~ /^(${${$config}{$tmp}}[3])$/i){
  				${$job}{$tmp} = lc($1);
  			}else{
  				print "Invalid value for ".join(">",@{$job_path}).">$tmp: ${$job}{$tmp}\n";
  				$error = 1;
  			}
			}
		}
	}
	return $error;
}

##
## CONFIG HANDLING
##
sub parse_job_config {
	my ($file)=@_;
	my %job;
	my $line_no = 0;
	copy_job(\%{$job{$file}},\%job_definition);
	
	my @parse_key;
	my @val;
	return %job if !-f "$::ETCPATH/jobs/$file";
	my @tmp = ::read_log("$::ETCPATH/jobs/$file");
	undef @parse_key;
	while (my $line = shift @tmp){
		chomp($line);
		$line_no++;
		$line =~ s/\{/ \{/g;
		$line =~ s/^\s+|\s+$//g;
		next if $line =~ /^$|^#/;
		if(($line =~ /\}/ && $line !~ /^\}$/) || $line =~ /^\{$/){
			print "Syntax error in job file $file, line $line_no\n";
			undef %job;
			return %job;
		}
		@val = split /\s+/, $line;
		if($line =~ /\{|\}/){
			pop @parse_key if $line =~ /\}/;
			push @parse_key, $val[0] if $line =~ /\{/;
		}else{
			$line =~ s/^$val[0]\s+//;
			$job{$file}{$val[0]} = $line if scalar @parse_key == 0 && defined $job{$file}{$val[0]};
			$job{$file}{$parse_key[0]}{$val[0]} = $line if scalar @parse_key == 1 && defined $job{$file}{$parse_key[0]}{$val[0]};
			$job{$file}{$parse_key[0]}{$parse_key[1]}{$val[0]} = $line if scalar @parse_key == 2 && defined $job{$file}{$parse_key[0]}{$parse_key[1]}{$val[0]};
		}
	}
	if(scalar @parse_key != 0){
		print "Syntax error in job file $file, not properly structured\n";
		undef %job;
	}
	
	my @job_path = ();
	if(verify_job(\%{$job{$file}},\%job_definition,\@job_path)){
		print "Syntax error in job file $file\n";
		undef %job;
	}
	
	return %job;
}

sub load_jobs_config {
	my %job;
	opendir (DIR, $::ETCPATH."/jobs/") or die $!;
	while (my $file = readdir(DIR)){
		next if $file =~ m/^\./;
		next if !-f "$::ETCPATH/jobs/$file";
		%job = (%job, parse_job_config($file));
	}
	return %job;
}

1;