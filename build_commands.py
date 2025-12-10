from setuptools.command.install import install
from setuptools.command.develop import develop
from setuptools.command.egg_info import egg_info
from setuptools.command.build_ext import build_ext
import subprocess
import os


def customize(command):
	command_name = str(command.mro()[1].__name__).strip()
	original_run = command.run

	def run(self):
		# Run the rest of the installer first
		original_run(self)
		# Create a new subprocess to run the included shell script
		print("Running " + command_name + " commands...")
		current_dir_path = os.path.dirname(os.path.realpath(__file__))
		create_service_script_path = os.path.join(current_dir_path, 'setup.sh')
		if os.path.exists(create_service_script_path):
			# stdout and stderr are combined in shell output
			output = subprocess.run(
				[create_service_script_path, command_name],
				stdout=subprocess.PIPE,
				stderr=subprocess.STDOUT,
				cwd=current_dir_path,
			).stdout
			print(output.decode('UTF-8'))
		else:
			print("setup.sh not found; skipping post-" + command_name + " actions.")

	command.run = run
	return command


@customize
class CustomInstallCommand(install):
	pass


@customize
class CustomDevelopCommand(develop):
	pass


@customize
class CustomEggInfoCommand(egg_info):
	pass


@customize
class CustomBuildExtCommand(build_ext):
	pass


