=head1 NAME

 Software::Packager::Aix

=head1 SYNOPSIS

 use Software::Packager;
 my $packager = new Software::Packager('aix');

=head1 DESCRIPTION

 This module is used to create software packages in a format suitable for
 installation with installp.
 The procedure is baised heaverly on the lppbuild version 2.1 scripts.
 It creates AIX 4.1 and higher packages only.

=head1 FUNCTIONS

=cut

package		Software::Packager::Aix;

####################
# Standard Modules
use strict;
use File::Path;
# Custom modules
use Software::Packager;
use Software::Packager::Object::Aix;

####################
# Variables
our @ISA = qw( Software::Packager );
our @EXPORT = qw();
our @EXPORT_OK = qw();
our $VERSION = 0.05;

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
# Function:	package()
# Description:	This function finalises the creation of the package.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub package
{
	my $self = shift;

	unless ($self->setup())
	{
		warn "Error: Problems were encountered in the setup phase\n";
		return undef;
	}
	unless ($self->cleanup())
	{
		warn "Error: Problems were encountered in the cleanup phase\n";
		return undef;
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
# Function:	setup()

=head2 B<setup()>

 This method sets up the temporary build structure.

=cut
sub setup
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	mkpath($tmp_dir, 1, 0750) or
		warn "Error: problems were encountered creating directory \"$tmp_dir\": $!\n";

	return 1;
}

################################################################################
# Function:	cleanup()

=head2 B<cleanup()>

 This method cleans up after us.

=cut
sub cleanup
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	# there has to be a better way to to this!
	return undef unless system("chmod -R 0777 $tmp_dir") eq 0;

	rmtree($tmp_dir, 1, 1);

	return 1;
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
	return $self->{'PACKAGE_VERSION'};
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
