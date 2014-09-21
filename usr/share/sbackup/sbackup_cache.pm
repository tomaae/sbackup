package sbackup_cache;  

###########################################################################################
#
#                                         sbackup
#                                          cache
#
###########################################################################################

BEGIN {
  $MODULE_NAME = "sbackup_cache";
  push @main::DEBUGHEADERS,"DEBUGGER: module: $MODULE_NAME";
  
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	@ISA         = qw(Exporter);
	@EXPORT      = qw(&f_get_history);
	%EXPORT_TAGS = ( );

	# exported package globals, as well as any optionally exported functions
	@EXPORT_OK   = qw();
}
our @EXPORT_OK;

use Fcntl ':flock';


sub f_parse_select{
	my ($table,$entry)=@_;
	my @select_request;
	my $i;
	my $tmp;
	
	$entry =~ s/ \, /\n/g;
	my @entries = split(/,/,$entry,-1);
 
	my %columns = (
    "status"=>0,
    "name"=>1,
    "uuid"=>2,
    "start"=>3,
    "end"=>4,
    "size"=>5,
    "perf"=>6,
    "type"=>7
  );
  
  $i = 0;
  for $tmp(@entries){
  	$select_request[$i]{'key'} = $tmp;
	  $select_request[$i]{'value'} = $columns{$tmp};
	  $i++;
  }

	return @select_request;
}

sub f_get_history{
	my ($uuid,$select,$where)=@_;
	
	my @val;
	my $tmp;
	my $line;
	my @cache;
	my $display_value;	
	my $return_counter = -1;
	
  my @select_request = &f_parse_select('history',$select);
  
  open log_file,"<".$main::HISTORYPATH.$main::s_slash.'history_'.$uuid;
	flock log_file,1;
	while($line = <log_file>){
  	chomp($line);
  	@val = split '\|',$line;
  	push @cache,[@val];
	}
	flock log_file,8;
  close log_file;

	for $val(@cache){
		$display_value = 0;
		if($where){
			###############
		}else{
			$display_value = 1;
		}
		
		if($display_value){
  		$returncodes[0] = 1;
  		$return_counter++;
  		for $tmp(@select_request){
  			$returncodes[2][$return_counter]{$$tmp{'key'}} = $$val[$$tmp{'value'}];
      }     
  	}
	}
	
	##Select output
	return @returncodes;

}

1;