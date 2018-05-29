package omv4;

###########################################################################################
#
#                                         sbackup
#                                     OMV4 integration
#
###########################################################################################

use strict;
use warnings;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(omv_prepare_sharedfolder);

##
## omv_name_by_uuid
##
sub omv_name_by_uuid {
	my $uuid = shift;
	my $result = "";
	$result = `. /usr/share/openmediavault/scripts/helper-functions&&omv_get_sharedfolder_name \"$uuid\"`;
	if($? != 0){
		$result = "Error:OMV name not found";
	}
	return $result;
}

##
## omv_mnt_by_uuid
##
sub omv_mnt_by_uuid {
	my $uuid = shift;
	my $result = "";
	$result = `. /usr/share/openmediavault/scripts/helper-functions&&omv_get_sharedfolder_mount_dir \"$uuid\"`;
	if($? != 0 || $result eq ""){
		$result = "Error:OMV mnt not found";
	}
	return $result;
}

##
## omv_path_by_uuid
##
sub omv_path_by_uuid {
	my $uuid = shift;
	my $result = "";
	$result = `. /usr/share/openmediavault/scripts/helper-functions&&omv_get_sharedfolder_path \"$uuid\"`;
	if($? != 0 || $result eq ""){
		$result = "Error:OMV path not found";
	}else{
		$result = "Error:OMV path does not exists" if !-d $result;
	}
	return $result;
}

##
## omv_uuid_by_name
##
sub omv_uuid_by_name {
	my $sharedfolder_name = shift;
	my $result = "";
	$result = `. /usr/share/openmediavault/scripts/helper-functions&&omv_config_get \"/config/system/shares/sharedfolder[name=\'$sharedfolder_name\']/uuid\"`;
	if($? != 0 || $result eq ""){
		$result = "Error:OMV failed to get uuid";
	}
	return $result;
}

##
## omv_is_mounted
##
sub omv_is_mounted {
	my $mnt = shift;
	my $result = "";
	$result = `. /usr/share/openmediavault/scripts/helper-functions&&omv_is_mounted \"$mnt\"`;
	if($? != 0){
		$result = "Error:OMV mnt not mounted";
	}
	return $result;
}

##
## omv_prepare_sharedfolder
##
sub omv_prepare_sharedfolder {
	my $sharedfolder_name = shift;
	my $result = "";
	&::f_output("DEBUG","Preparing OMV sharedfolder \"$sharedfolder_name\"");
	##Get uuid
	my $uuid = omv_uuid_by_name($sharedfolder_name);
	&::f_output("DEBUG","sharedfolder UUID \"$uuid\"");
	##Get mount point
	my $uuid_mnt = omv_mnt_by_uuid($uuid);
	&::f_output("DEBUG","sharedfolder mnt \"$uuid_mnt\"");
	return $uuid_mnt if $uuid_mnt =~ /^Error:/;
	##Verify if mounted
	$result = omv_is_mounted($uuid_mnt);
	return $result if $result =~ /^Error:/;
	##Get path
	my $uuid_path = omv_path_by_uuid($uuid);
	&::f_output("DEBUG","sharedfolder path \"$uuid_path\"");
	return $uuid_path if $uuid_path =~ /^Error:/;
	
	$result = $uuid_path;
	return $result;
}

1;