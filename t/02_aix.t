# t/03_aix.t; load Software::Packager and create an AIX package

use Software::Packager;
use Cwd;
use Config;
use Test;

BEGIN
{
	if ($Config{'osname'} =~ /aix/i)
	{
		plan( tests => 23 , todo => [23]);
	}
	else
	{
		plan(tests=>0);
		exit 0;
	}
}

$|++; 
my $test_number = 1;
my $comment = "";

my $packager = new Software::Packager('aix');
print_status($packager);

$packager->package_name('AIXTestPackage');
my $package_name = $packager->package_name();
same('AIXTestPackage', $package_name);

$packager->description("This is a description");
my $description = $packager->description();
same("This is a description", $description);

$packager->version('4.3.2.1');
same('4.3.2.1' ,$packager->version());

$packager->version('2');
same('2.1.0.0', $packager->version());

my $cwd_output_dir = getcwd();
$packager->output_dir($cwd_output_dir);
my $output_dir = $packager->output_dir();
same("$cwd_output_dir", $output_dir);

$packager->category("Applications");
my $category = $packager->category();
same("Applications", $category);

$packager->architecture("None");
my $architecture = $packager->architecture();
same("None", $architecture);

$packager->icon("None");
my $icon = $packager->icon();
same("None", $icon);

$packager->prerequisites("None");
my $prerequisites = $packager->prerequisites();
same("None", $prerequisites);

$packager->vendor("Gondwanatech");
my $vendor = $packager->vendor();
same("Gondwanatech", $vendor);

$packager->email_contact('rbdavison@cpan.org');
my $email_contact = $packager->email_contact();
same('rbdavison@cpan.org', $email_contact);

$packager->creator('R Bernard Davison');
my $creator = $packager->creator();
same('R Bernard Davison', $creator);

$packager->install_dir("perllib");
my $install_dir = $packager->install_dir();
same("perllib", $install_dir);

$packager->program_name("softwarepackager");
same("softwarepackager", $packager->program_name());

$packager->component_name("aix");
same("aix", $packager->component_name());

# test 14
$packager->tmp_dir("t/aix_tmp_build_dir");
my $tmp_dir = $packager->tmp_dir();
same("t/aix_tmp_build_dir", $tmp_dir);

# test 15
# so we have finished the configuration so add the objects.
open (MANIFEST, "< MANIFEST") or warn "Cannot open MANIFEST: $!\n";
my $add_status = 1;
my $cwd = getcwd();
while (<MANIFEST>)
{
	my $file = $_;
	chomp $file;
	my @stats = stat $file;
	my %data;
	$data{'TYPE'} = 'File';
	$data{'TYPE'} = 'Directory' if -d $file;
	$data{'SOURCE'} = "$cwd/$file";
        if ($file =~ /etc/)
        {
                $data{'DESTINATION'} = $file;
        }
        else
        {
                $data{'DESTINATION'} = "/usr/lib/perl/$file";
        }
	$data{'MODE'} = sprintf "%04o", $stats[2] & 07777;
	$add_status = undef unless $packager->add_item(%data);
}
print_status($add_status);
close MANIFEST;
foreach my $dir  ("lib", "lib/Software", "lib/Software/Packager", "lib/Software/Packager/Object", "t")
{
	my @stats = stat $dir;
	my %data;
	$data{'TYPE'} = 'Directory';
	$data{'DESTINATION'} = "/usr/lib/perl/$dir";
	$data{'MODE'} = sprintf "%04o", $stats[2] & 07777;
	$add_status = undef unless $packager->add_item(%data);
}
print_status($add_status);

# test 16
my %hardlink;
$hardlink{'TYPE'} = 'Hardlink';
$hardlink{'SOURCE'} = "lib/Software/Packager/Aix.pm";
$hardlink{'DESTINATION'} = "/usr/lib/perl/HardLink.pm";
print_status($packager->add_item(%hardlink));

# test 17
my %softlink;
$softlink{'TYPE'} = 'softlink';
$softlink{'SOURCE'} = "lib/Software";
$softlink{'DESTINATION'} = "/usr/lib/perl/SoftLink";
print_status($packager->add_item(%softlink));

# test 18
print_status($packager->package());

# test 19
my $package_file = $packager->output_dir();
$package_file .= "/" . $packager->package_name();
$package_file .= ".bff";
$comment = "# As the package creation is not finished we have no package to test for";
print_status(-f $package_file);

# test 20
#warn $packager->_find_lpp_type(), "\n";

####################
# Functions to use
sub same
{
	my $expected = shift;
	my $got = shift;
	if ($expected eq $got)
	{
		print_status(1);
	}
	else
	{
		$comment = " # Expected:\"$expected\" but Got:\"$got\"" unless $comment;
		print_status(0, $comment);
	}
	$comment = "";
}

sub print_status
{
	my $value = shift;
	if ($value)
	{
		print "ok $test_number\n";
	}
	else
	{
		print "not ok $test_number $comment\n";
	}
	$test_number++;
	$comment = "";
}


