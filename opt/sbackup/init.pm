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
									get_env 
									$slash $BINPATH $MODULESPATH $ETCPATH $JOBCONFIGPATH $HISTORYPATH $SESSIONLOGPATH $RUNFILEPATH
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

1;