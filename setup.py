from setuptools import setup, find_packages
import glob

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
	zip_safe=True
)
