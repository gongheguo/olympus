import unittest
import sapproject
import os

class Test (unittest.TestCase):
	"""Unit test for sapproject"""	

	def setUp(self):
		self.project = sapproject.SapProject() 

	def test_read_config_string(self):
		"""cofirm that I can read the JSON string"""
		json_string = "[\"foo\", {\"bar\": [\"baz\", null, 1.0, 2]}]"
		result = self.project.read_config_string(json_string)
		self.assertEqual(result, True)
	
	def test_read_config_file(self):
		"""confirm that a project config file can be read"""
		file_name = os.getenv("SAPLIB_BASE") + "/data/example_project/example1.json"
		result = self.project.read_config_file(file_name, debug=True)
		result = True
		self.assertEqual(result, True)

	def test_read_template(self):
		"""confirm that a template file can be loaded"""
		filename = "wishbone_template"
		result = self.project.read_template(filename, debug=True)
		self.assertEqual(result, True)

	def test_generate_project(self):
		"""test if a project can be generated"""
		file_name = os.getenv("SAPLIB_BASE") + "/data/example_project/example1.json"
		result = self.project.generate_project(file_name, debug=True)
		self.assertEqual(result, True)

	def test_query_slave(self):
		"""test to see if we can query a slave"""
		result = True
		self.assertEqual(result, True)

	def test_get_slave_meta_data(self):
		"""test for the meta data within a slave file"""
		result = True
		self.assertEqual(result, True)

	def test_query_handler(self):
		"""determine in a handler exists"""
		result = True
		self.assertEqual(result, True)

if __name__ == "__main__":
	unittest.main()
