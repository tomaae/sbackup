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
our @EXPORT = qw(load_jobs_config parse_job_config job_exists list_jobs);


my %job_definition = ( ##Default value, Mandatory, Type, Range of type
  'NAME' => ["",1,"",""],
  'ENABLED' => ["0",1,"bool",""],
  'SCHEDULE' => {
  	'-enabled' => ["0",0,"bool",""],
  	'-day' => ["",0,"day",""],
  	'-time' => ["",0,"time",""],
  	'-automatic' => ["",0,"list","daily|weekly"],
  },
  'SOURCE' => {
  	'-type' => ["",1,"list","filesystem|omv4"],
  	'-host' => ["",0,"",""],
  	'-path' => ["",1,"",""],
  	'-exclude' => ["",0,"",""],
  	'-protect' => ["0",1,"number",""],
  	'-snapshot' => {
  		'-enabled' => ["0",1,"bool",""],
  		'-type' => ["",0,"list","lvm"],
  		'-size' => ["",0,"number",""],
  		'-fallback' => ["0",0,"bool",""],
  	}
  },
  'TARGET' => {
  	'-type' => ["",1,"list","filesystem|omv4"],
  	'-host' => ["",0,"",""],
  	'-path' => ["",1,"",""],
  	'-bwlimit' => ["0",0,"number",""],
  	'-bwcompress' => ["0",0,"bool",""],
  },
  'COPY' => {
  	'-type' => ["",0,"list","filesystem|omv4"],
  	'-host' => ["",0,"",""],
  	'-path' => ["",0,"",""],
  	'-bwlimit' => ["0",0,"number",""],
  	'-bwcompress' => ["0",0,"bool",""],
  },
  'POST' => {
  	'-preexec' => ["",0,"",""],
  	'-postexec' => ["",0,"",""],
  	'-job' => {
  		'-type' => ["",0,"list","backup|restore"],
  		'-name' => ["",0,"",""],
  	},
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
  				print "Invalid value for bool ".join(">",@{$job_path}).">$tmp: ${$job}{$tmp}\n";
  				$error = 1;
  			}
			}
			##Numeric test
			if(defined ${$job}{$tmp} && ${${$config}{$tmp}}[2] eq "number"){
  			if(${$job}{$tmp} !~ /^[0-9]*$/){
  				print "Invalid value for numeric ".join(">",@{$job_path}).">$tmp: ${$job}{$tmp}\n";
  				$error = 1;
  			}
			}
			##List test
			if(defined ${$job}{$tmp} && ${$job}{$tmp} ne "" && ${${$config}{$tmp}}[2] eq "list"){
  			if(${$job}{$tmp} =~ /^(${${$config}{$tmp}}[3])$/i){
  				${$job}{$tmp} = lc($1);
  			}else{
  				print "Invalid value for list ".join(">",@{$job_path}).">$tmp: ${$job}{$tmp}\n";
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
	if(verify_job(\%{$job{$file}},\%job_definition,\@job_path) || $job{$file}{'NAME'} ne $file){
		print "Job name \"".$job{$file}{'NAME'}."\" and filename \"".$file."\" do not match.\n" if $job{$file}{'NAME'} ne $file;
		print "Syntax error in job file $file\n";
		undef %job;
	}
	
	return %job;
}

sub load_jobs_config {
	my %job;
	opendir(my $dh, $::ETCPATH."/jobs/") || f_output("ERROR","Error: Insufficient access rights.",1);;
	while (my $file = readdir($dh)){
		next if $file =~ m/^\./;
		next if !-f "$::ETCPATH/jobs/$file";
		%job = (%job, parse_job_config($file));
	}
	closedir $dh;
	return %job;
}

sub job_exists {
	my ($p_job)=@_;
	
	my $jobexists = 0;
	for my $tmp_job(sort keys %::job){
		$jobexists = 1 if $::job{$tmp_job}{'NAME'} eq $p_job;
	}
	return $jobexists;
}

sub list_jobs {
	my @joblist = ();
	for my $tmp(sort keys %::job){
		push @joblist, $::job{$tmp}{'NAME'}
	}
	return @joblist;
}

1;