=head1 NAME

 Software::Packager::Object::Aix

=head1 SYNOPSIS

 use Software::Packager::Object::Aix

=head1 DESCRIPTION

 This module is extends Software::Packager::Object and adds extra methods for
 use by the AIX software packager.

=head1 FUNCTIONS

=cut

package		Software::Packager::Object::Aix;

####################
# Standard Modules
use strict;
# Custom modules
use Software::Packager::Object;

####################
# Variables
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = qw( Software::Packager::Object );
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = 0.02;

####################
# Functions

=head2 B<lpp_type()>

 The LPP type for objects determines the type of LPP package created.
 If the objects destination is under /usr/share then the object is of type SHARE
 If the objects destination is under /usr then the object has a type of USER
 If the objects destination is under any other directory then the object has a
 type of ROOT+USER.

 Note: when using the methods
 lpp_type_is_share()
 lpp_type_is_user()
 lpp_type_is_root()
 If the lpp_type_is_share() returns true then both lpp_type_is_user() and
 lpp_type_is_root() will also return true.
 Also if lpp_type_is_user() returns true then lpp_type_is_root() will also
 return true.
 So when calling these method do something like...

 foreach my $object ($self->get_object_list())
 {
 	$share++ and next if $object->lpp_type_is_share();
 	$user++ and next if $object->lpp_type_is_user();
 	$root++ and next if $object->lpp_type_is_root();
 }

=cut

################################################################################
# Function:	lpp_type_is_share()

=head2 B<lpp_type_is_share()>

 $share++ if $object->lpp_type_is_share();

 Returns the true if the LPP is SHARE otherwise it returns undef.

=cut 
sub lpp_type_is_share
{
	my $self = shift;
	my $destination = $self->destination();
	return '1' if $destination =~ m#^/usr/share#;
	return undef;
}

################################################################################
# Function:	lpp_type_is_user()

=head2 B<lpp_type_is_user()>

 $share++ if $object->lpp_type_is_user();

 Returns the true if the LPP is USER otherwise it returns undef.

=cut 
sub lpp_type_is_user
{
	my $self = shift;
	my $destination = $self->destination();
	return '1' if $destination =~ m#^/usr#;
	return undef;
}

################################################################################
# Function:	lpp_type_is_root()

=head2 B<lpp_type_is_root()>

 $share++ if $object->lpp_type_is_root();

 Returns the true if the LPP is ROOT+USER otherwise it returns undef.

=cut 
sub lpp_type_is_root
{
	my $self = shift;
	my $destination = $self->destination();
	return '1' if $destination =~ m#^/#;
	return undef;
}

1;
__END__

=head1 SEE ALSO

 Software::Packager::Object

=head1 AUTHOR

 R Bernard Davison <rbdavison@cpan.org>

=head1 COPYRIGHT

 Copyright (c) 2001 Gondwanatech. All rights reserved.
 This program is free software; you can redistribute it and/or modify it under
 the same terms as Perl itself.

=cut
