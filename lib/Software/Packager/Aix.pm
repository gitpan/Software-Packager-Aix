=head1 NAME

Software::Packager::Aix - The Software::Packager extension for AIX 3.2 and above

=head1 SYNOPSIS

 use Software::Packager;
 my $packager = new Software::Packager('aix');

=head1 DESCRIPTION

This module is used to create software packages in a format suitable for
installation with installp.
The procedure is baised heaverly on the lppbuild version 2.1 scripts.
I believe these scripts to be written by Jim Abbey. Who ever it was thanks 
for your work. It has proven envaluable.
lppbuild is available from http://aixpdslib.seas.ucla.edu/
It creates AIX 4.1 and higher packages only.

=head1 FUNCTIONS

=cut

package		Software::Packager::Aix;

####################
# Standard Modules
use strict;
use File::Path;
use File::Copy;
use File::Basename;
use FileHandle 2.0;
use Cwd;
use Data::Dumper;
# Custom modules
use Software::Packager;
use Software::Packager::Object::Aix;

####################
# Variables
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = qw( Software::Packager );
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = 0.08;

####################
# Functions

################################################################################
# Function:	new()
# Description:	This function creates and returns a new Packager object.
# Arguments:	none.
# Return:	new Packager object.
#
sub new
{
	my $class = shift;
	my $self = bless {}, $class;

	return $self;
}

################################################################################
# Function:	add_item()

=head2 B<add_item()>

 The method overrides the add_item method of Software::Packager to use
 Software::Packager::Object::Aix.
 See Software::Packager for more details on this method.

=cut
sub add_item
{
	my $self = shift;
	my %data = @_;
	my $object = new Software::Packager::Object::Aix(%data);

	return undef unless $object;

	# check that the object has a unique destination
	return undef if $self->{'OBJECTS'}->{$object->destination()};

	$self->{'OBJECTS'}->{$object->destination()} = $object;
}

################################################################################
# Function:	lpp_package_type()

=head2 B<lpp_package_type()>

This method sets or returns the lpp package type.
The lpp package types are
"I" for an install package
"ML" for a maintenance level package
"S" for a single update package

If the lpp package type is not set, the default of "I" for an install package is 
set (version minor and fix numbers are 0) and "S" for an update package 
(version minor and fix numbers are non 0)

=cut
sub lpp_package_type
{
	my $self = shift;
	my $value = shift;
	if ($value)
	{
	    $self->{'LPP_PACKAGE_TYPE'} = $value;
	}
	else
	{
	    if ($self->{'LPP_PACKAGE_TYPE'})
            {
                return $self->{'LPP_PACKAGE_TYPE'};
            }
            else
            {
                if ($self->_lppmode() eq 'I')
                {
                    return 'I';
                }
                else
                {
                    return 'S';
                }
            }
	}
}

################################################################################
# Function:	component_name()

=head2 B<component_name()>

This method sets or returns the component name for this package.

=cut
sub component_name
{
	my $self = shift;
	my $value = shift;
	if ($value)
	{
	    $self->{'PACKAGE_COMPONENT'} = $value;
	}
	else
	{
            return $self->{'PACKAGE_COMPONENT'};
        }
}

################################################################################
# Function:	package()

=head2 B<package()>

$packager->package();
This function overrides the base API in Software::Packager. I controls the
process of package creation.

=cut
sub package
{
	my $self = shift;

        # Do some checks before we build.
        unless (scalar $self->program_name())
        {
                warn "Error: This package doesn't have the program name set. This is required.";
                return undef;
        }
        unless (scalar $self->component_name())
        {
                warn "Error: This package doesn't have the component name set. This is required.";
                return undef;
        }

	unless ($self->_setup())
	{
		warn "Error: Problems were encountered in the setup phase\n";
		return undef;
	}
	unless ($self->_cleanup())
	{
		warn "Error: Problems were encountered in the cleanup phase\n";
		return undef;
	}
	return 1;
}

################################################################################
# Function:	_setup()

=head2 B<_setup()>

 This method sets up the temporary build structure.

=cut
sub _setup
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	unless (-d $tmp_dir)
        {
            mkpath($tmp_dir, 0, 0750) or
		warn "Error: Problems were encountered creating directory \"$tmp_dir\": $!\n";
        }

        # create the package structure under the tmp_dir
	unless ($self->_create_package_structure())
        {
		warn "Error: Problems were encountered creating the package structure: $!\n";
                return undef;
        }

        # create the lpp_name file
	unless ($self->_create_lpp_name())
        {
		warn "Error: Problems were encountered creating the file lpp_name: $!\n";
                return undef;
        }

        # create the control files for hte package
	unless ($self->_create_control_files())
        {
		warn "Error: Problems were encountered creating the control files: $!\n";
                return undef;
        }
        
	return 1;
}

################################################################################
# Function:	_cleanup()

=head2 B<_cleanup()>

 This method cleans up after us.

=cut
sub _cleanup
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	# there has to be a better way to to this!
#	return undef unless system("chmod -R 0777 $tmp_dir") eq 0;
#	rmtree($tmp_dir, 1, 1);

	return 1;
}

################################################################################
# Function:	_version()

=head2 B<_version()>

 This method overrides Software::Packager::_version
 This method is used to format the version and return it in the desired format 
 for the current packaging system.

=cut
sub _version
{
	my $self = shift;

        my ($major, $release, $minor, $fix) = split /\./, $self->{'PACKAGE_VERSION'};
        # check that we have 4 parts if not then create them
        $major = 0 unless $major;
        $release = 0 unless $release;
        $minor = 0 unless $minor;
        $fix = 0 unless $fix;

        # check that the major and release values are non zero.
        $major = 1 if $major <= 0;
        $release = 1 if $release <= 0;

        # set the lppmode
        if (($minor eq 0) and ($fix eq 0))
        {
            $self->_lppmode('I');
        }
        else
        {
            $self->_lppmode('U');
        }

        $self->{'PACKAGE_VERSION'} = $major .".". $release .".". $minor .".". $fix;
	return $self->{'PACKAGE_VERSION'};
}

################################################################################
# Function:	_check_version()

=head2 B<_check_version()>

 This method is used to check the format of the version and returns true, if
 there are any problems then it returns undef;
 This method overrides Software::Packager::_check_version
 Test that the format is digits and periods anything else is a no good.
 The first and second numbers must have 1 or 2 digits
 The rest can have 1 to 4 digits.

=cut
sub _check_version
{
	my $self = shift;
	my $value = shift;
	return undef if $value =~ /\D!\./;

        # check if we have 4 parts
        my @number = split /\./, $value;
        if (scalar @number < 4)
        {
                warn "Warning: Version does not meet the specified format vv.rr.mm.ff it will be modified.\n";
        }

        my ($major, $release, @rest) = split /\./, $value;
        # check that we have 4 parts if not then create them
        $major = 0 unless $major;
        $release = 0 unless $release;

        # check that each part is valid
        if ($major <= 0)
        {
                warn "Warning: Major version is zero or less. This does not meet the specifications.\n";
                warn "         The major version will be modified to meet the standard.\n";
        }
	if ($release <= 0)
        {
                warn "Warning: Release version is zero or less. This does not meet the specifications.\n";
                warn "         The release version will be modified to meet the standard.\n";
        }

	return 1;
}

################################################################################
# Function:	_find_lpp_type()

=head2 B<_find_lpp_type()>

 This method finds the type of LPP we are building.
 If all components are under /usr/share then the part is a SHARE package.
 If all components are under /usr then the part is a USER package.
 If components are under any other directory then the part is a ROOT+USER package.

 ROOT only parts are not permitted.
 SHARE + ROOT and or USER parts are not permitted.

 Returns the LPP code for the part type on success and undef if there are
 errors.
 a USER part will return U
 a ROOT+USER part will return B
 a SHARE part will return H

=cut
sub _find_lpp_type
{
	my $self = shift;
	my $share = 0;
	my $user = 0;
	my $root = 0;

	foreach my $object ($self->get_object_list())
	{
		if ($object->lpp_type_is_share()){ $share++; next;};
		if ($object->lpp_type_is_user()){ $user++; next;};
		if ($object->lpp_type_is_root()){ $root++; next;};
	}

	if ($share and $user)
	{
		warn "Error: Packages with SHARE and USER parts are not permitted.\n";
		return undef;
	}
	elsif ($share and $root)
	{
		warn "Error: Packages with SHARE and ROOT parts are not permitted.\n";
		return undef;
	}
	elsif ($root) { return 'B'; }
	elsif ($user) { return 'U'; }
	elsif ($share) { return 'H'; }
	else
	{
		warn "Error: Package type could not be determined.\n";
		return undef;
	}
}

################################################################################
# Function:	_lppmode()

=head2 B<_lppmode()>

This method sets or returns the lppmode.
The lppmode can be either install (I) or update (U). This is set when the 
version is set.

=cut
sub _lppmode
{
	my $self = shift;
	my $value = shift;
	if ($value)
	{
	    $self->{'LPPMODE'} = $value;
	}
	else
	{
	    return $self->{'LPPMODE'};
	}
}

################################################################################
# Function:	_create_lpp_name()

=head2 B<_create_lpp_name()>

This method creates the file lpp_name for the package.

=cut
sub _create_lpp_name
{
        my $self = shift;
        my $lpp_name_file = $self->tmp_dir() . "/lpp_name";
        my $lpp_name = new FileHandle();
        $lpp_name->open(">$lpp_name_file");

        $lpp_name->print("4 R");
        $lpp_name->print(" " . $self->lpp_package_type());
        $lpp_name->print(" " . $self->program_name());
        $lpp_name->print(" {\n");

        $lpp_name->print(" " . $self->program_name() .".". $self->component_name());
        $lpp_name->print(" " . $self->version());

        # not sure what this is for. I'll have to check the specs.
        $lpp_name->print(" 1");

        if ($self->reboot_required())
        {
            $lpp_name->print(" b");
        }
        else
        {
            $lpp_name->print(" N");
        }
        $lpp_name->print(" " . $self->lpp_package_type());

        $lpp_name->print(" en_US");
        $lpp_name->print(" ". $self->description() . "\n");
        $lpp_name->print("[\n");

        if ($self->prerequisites())
        {
            # This needs to be implemented.
        }
        $lpp_name->print("\%\n");
        $lpp_name->print($self->_find_disk_usage());

        # need to implement page space.
        # need to implement install space. (space required to extract crontrol files from liblpp.a
        # need to implement save space.

        $lpp_name->print("\%\n");
        
        # need to implement supersede ability

        $lpp_name->print("\%\n");

        # need to implement fix information

        $lpp_name->print("]\n");
        $lpp_name->print("}\n");
        $lpp_name->close();
}

################################################################################
# Function:	_find_disk_usage()

=head2 B<_find_disk_usage()>

This method finds the disk usage for the package directories

=cut
sub _find_disk_usage
{
    my $self = shift;
    my $dir = $self->tmp_dir();
    my $cwd = getcwd();
    chdir $dir;
    
    # find the directories
    my @directories = `find . ! -type d -exec dirname {} \\; | sort -u`;

    # find the disk usage
    my $usage;
    foreach my $dir (@directories)
    {
        chomp $dir;
        $dir = "./" if $dir eq ".";
        $usage .= `du -s $dir |awk '{print substr(\$2,2) " " \$1}'`;
    }

    chdir $cwd;
    return $usage;
}

################################################################################
# Function:	_create_package_structure()

=head2 B<_create_package_structure()>

This method creates the package structure for the package under the tmp 
directory.

=cut
sub _create_package_structure
{
        my $self = shift;
        my $tmp_dir = $self->tmp_dir();

        foreach my $object ($self->get_directory_objects(), $self->get_file_objects(), $self->get_link_objects())
        {
                my $destination = "$tmp_dir/". $object->destination();
                my $source = $object->source();
                my $type = $object->type();
                my $mode = $object->mode();
                my $user = $object->user();
                my $group = $object->group();

		if ($type =~ /directory/i)
		{
			unless (-d $destination)
                        {
                            mkpath($destination, 0, oct($mode));
                        }
                        unless (system("chown $user $destination") eq 0)
                        {
                            warn "Error: Couldn't set the user to \"$user\" for \"$destination\": $!\n";
                            return undef;
                        }
                        unless (system("chgrp $group $destination") eq 0)
                        {
                            warn "Error: Couldn't set the group to \"$group\" for \"$destination\": $!\n";
                            return undef;
                        }
		}
                elsif ($type =~ /file/i)
                {
                        my $directory = dirname($destination);
                        unless (-d $directory)
                        {
                                warn "Error: Directory \"$directory\" is not in the package. This is not permitted. Please add an entry for this directory and try again.\n";
                                return undef;
                        }
                        copy($source, $destination);
                        unless (system("chown $user $destination") eq 0)
                        {
                            warn "Error: Couldn't set the user to \"$user\" for \"$destination\": $!\n";
                            return undef;
                        }
                        unless (system("chgrp $group $destination") eq 0)
                        {
                            warn "Error: Couldn't set the group to \"$group\" for \"$destination\": $!\n";
                            return undef;
                        }
                        unless (system("chmod $mode $destination") eq 0)
                        {
                            warn "Error: Couldn't set the mode to \"$mode\" for \"$destination\": $!\n";
                            return undef;
                        }
                }
                elsif ($type =~ /hard/i)
		{
                        unless (link $source, $destination)
                        {
                            warn "Error: Could not create hard link from $source to $destination:\n$!\n";
                            return undef;
                        }
                }
                elsif ($type =~ /soft/i)
		{
                        unless (symlink $source, $destination)
                        {
                                warn "Error: Could not create soft link from $source to $destination:\n$!\n";
                                return undef;
                        }
                }
                else
                {
                        warn "Warning: Don't know what type of object \"$destination\" is.\n";
                }
        }
        return 1;
}

################################################################################
# Function:	_create_control_files()

=head2 B<_create_control_files()>

This method creates the lpp control files (liblpp.a).

=cut
sub _create_control_files
{
	my $self = shift;
        my $tmp_dir = $self->tmp_dir();

        my ($user, $root) = $self->_control_file_names();
        # if we couldn't find the control file names then undef would heve been
        # returned so return undef
        return undef unless $user;

        # This is a list of possible config files that can be added to the liblpp.a archive.
        # TODO: need to make a method to set all of these files.
        my @config_files = qw( cfginfo cfgfiles err fixdata namelist odmadd rm_inv trc config config_u odmdel pre_d pre_i pre_u pre_rm posti post_u unconfig unconfig_u unodmadd unport_i unpost_u unpre_i unpre_u copyright );

        # restructure the tmp directory
        unless (-d $root)
        {
            mkpath($root, 0, 0755);
        }
        unless (-d $user)
        {
            mkpath($user, 0, 0755);
        }
        my @items = `ls $tmp_dir`;
        foreach my $item (@items)
        {
                chomp $item;
                next if $item eq 'usr';
                next if $item eq 'lpp_name';
                # everything else must be part of the root install
                move("$tmp_dir/$item", "$root/$item");
        }

        # create the apply list
        $self->_create_apply_lists();

        # create the invertory file

        warn "USER:\"$user\"\nROOT:\"$root\"\n";
}

################################################################################
# Function:	_control_file_names()

=head2 B<_control_file_names()>

This method the names for the user and root control file (liblpp.a) locations.

=cut
sub _control_file_names
{
	my $self = shift;
        my $tmp_dir = $self->tmp_dir();
        my $root;
        my $user;
        if ( ($self->_find_lpp_type() eq 'B') or ($self->_find_lpp_type() eq 'U') )
        {
            if ($self->_lppmode() eq 'I')
            {
                # we have an install
                $root = "$tmp_dir/usr/lpp/" . $self->program_name() ."/inst_root";
                $user = "$tmp_dir/usr/lpp/" . $self->program_name();
            }
            else
            {
                # we have an update
                $root = "$tmp_dir/usr/lpp/" . $self->program_name();
                $root .= "/". $self->program_name();
                $root .= ".". $self->component_name();
                $root .= "/". $self->version() ."/inst_root";
                $user = "$tmp_dir/usr/lpp/" . $self->program_name();
                $user .= "/". $self->program_name();
                $user .= ".". $self->component_name();
                $user .= "/". $self->version();
            }
        }
        elsif ($self->_find_lpp_type() eq 'H')
        {
            if ($self->_lppmode() eq 'I')
            {
                # we have an install
                $root = "$tmp_dir/usr/share/lpp/" . $self->program_name();
                $user = "$tmp_dir/usr/share/lpp/" . $self->program_name();
            }
            else
            {
                # we have an update
                $root = "$tmp_dir/usr/share/lpp/" . $self->program_name();
                $root .= "/". $self->program_name();
                $root .= ".". $self->component_name();
                $root .= "/". $self->version();
                $user = "$tmp_dir/usr/share/lpp/" . $self->program_name();
                $user .= "/". $self->program_name();
                $user .= ".". $self->component_name();
                $user .= "/". $self->version();
            }
        }
        else
        {
            warn "Error: Cannot find the lpp type si I cannot determine the location of the control files.\n";
            return undef;
        }
        return $user, $root;
}

################################################################################
# Function:	_create_apply_lists()

=head2 B<_create_apply_lists()>

This method creates the apply list to be included in the liblpp.a.

=cut
sub _create_apply_lists
{
	my $self = shift;
}

1;
__END__

=head1 SEE ALSO

 Software::Packager

=head1 AUTHOR

 Bernard Davison <rbdavison@cpan.org>

=head1 HOMEPAGE

 http://bernard.gondwana.com.au

=head1 COPYRIGHT

 Copyright (c) 2001 Gondwanatech. All rights reserved.
 This program is free software; you can redistribute it and/or modify it under
 the same terms as Perl itself.

=cut
