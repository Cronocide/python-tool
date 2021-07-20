from setuptools import setup, find_packages
from setuptools.command.install_scripts import install_scripts
from setuptools.command.install import install
from setuptools.command.develop import develop
from setuptools.command.egg_info import egg_info
import subprocess
import os
import glob


# From https://stackoverflow.com/questions/5932804/set-file-permissions-in-setup-py-file
class CustomInstallCommand(install) :
	def run(self) :
		# Run the rest of the installer first
		install.run(self)
		# Create a new subprocess to run the included shell script
		current_dir_path = os.path.dirname(os.path.realpath(__file__))
		create_service_script_path = os.path.join(current_dir_path, 'install_systemd_service.sh')
		subprocess.check_output([create_service_script_path])



# From https://stackoverflow.com/questions/5932804/set-file-permissions-in-setup-py-file
class CustomDevelopCommand(develop) :
	def run(self) :
		# Run the rest of the installer first
		develop.run(self)
		# Create a new subprocess to run the included shell script
		current_dir_path = os.path.dirname(os.path.realpath(__file__))
		create_service_script_path = os.path.join(current_dir_path, 'install_systemd_service.sh')
		subprocess.check_output([create_service_script_path])

# From https://stackoverflow.com/questions/5932804/set-file-permissions-in-setup-py-file
class CustomEggInfoCommand(egg_info) :
	def run(self) :
		# Run the rest of the installer first
		egg_info.run(self)
		# Create a new subprocess to run the included shell script
		current_dir_path = os.path.dirname(os.path.realpath(__file__))
		create_service_script_path = os.path.join(current_dir_path, 'install_systemd_service.sh')
		subprocess.check_output([create_service_script_path])

files = glob.glob('python-tool/externals/*.py')

setup(name='python-tool',
	version='1.0.0',
	url='',
	license='Apache2',
	author='Daniel Dayley',
	author_email='github@cronocide.com',
	description='',
	packages=find_packages(exclude=['tests']),
	package_data={"": ['externals/*.py']},
	install_requires=['pyyaml', 'vsphere-automation-sdk @ git+https://github.com/vmware/vsphere-automation-sdk-python.git'],
	scripts=['bin/python-tool'],
	long_description=open('README.md').read(),
	zip_safe=True,
	cmdclass={'install':CustomInstallCommand,'develop':CustomDevelopCommand,'egg_info':CustomEggInfoCommand}
)
