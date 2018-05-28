package omv;

###########################################################################################
#
#                                         sbackup
#                                     OMV integration
#
###########################################################################################

use strict;
use warnings;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(omv_name_by_uuid omv_mnt_by_uuid omv_path_by_uuid omv_is_mounted omv_prepare_uuid);

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
#      <sharedfolder>
#        <uuid>c39e30a8-9201-4b0f-a848-07a5f18ec533</uuid>
#        <name>backuptest</name>
#        <comment></comment>
#        <mntentref>f8092d74-045d-449b-b5b5-de11fdfdf7f2</mntentref>
#        <reldirpath>backuptest/</reldirpath>
#        <privileges></privileges>
#      </sharedfolder>

	#. /usr/share/openmediavault/scripts/helper-functions&&omv_config_get "//config/system/shares/sharedfolder[name='backuptest']"
	$result = `. /usr/share/openmediavault/scripts/helper-functions&&omv_get_sharedfolder_path \"$uuid\"`;
	if($? != 0 || $result eq ""){
		$result = "Error:OMV path not found";
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
## omv_prepare_uuid
##
sub omv_prepare_uuid {
	my $uuid = shift;
	my $result = "";
	&::f_output("DEBUG","Preparing OMV uuid \"$uuid\"");
	##Get mount point
	my $uuid_mnt = omv_mnt_by_uuid($uuid);
	return $uuid_mnt if $uuid_mnt =~ /^Error:/;
	##Verify if mounted
	$result = omv_is_mounted($uuid_mnt);
	return $result if $result =~ /^Error:/;
	##Get path
	my $uuid_path = omv_path_by_uuid($uuid);
	return $uuid_path if $uuid_path =~ /^Error:/;
	
	$result = $uuid_path;
	return $result;
}

1;