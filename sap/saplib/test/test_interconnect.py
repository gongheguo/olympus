import unittest
from gen import Gen
import os
from inspect import isclass

class Test (unittest.TestCase):
	"""Unit test for sapfile"""

	def setUp(self):
		"""open up a sapfile class"""
		#self.gen = gen_interconnect.GenInterconnect()

	def test_gen_interconnect (self):
		"""Generate an actual interconnect file"""
		interconnect_buffer = ""
		tags = {"SLAVES":["slave1", "slave2"]}
		try:
			filename = os.getenv("SAPLIB_BASE") + "/data/hdl/rtl/wishbone/interconnect/wishbone_interconnect.v"
			filein = open(filename)
			interconnect_buffer = filein.read()
			filein.close()
		except IOError as err:
			print "File Error: " + str(err)

#		print "buf: " + interconnect_buffer
		self.gen_module = __import__("gen_interconnect")
		for name in dir(self.gen_module):
			obj = getattr(self.gen_module, name)
			if isclass(obj) and issubclass(obj, Gen) and obj is not Gen:
				self.gen = obj()
				print "found " + name
				
		#self.gen = self.gen_module.Gen()
		result = self.gen.gen_script(tags, buf = interconnect_buffer)

		#write out the file
		try:
			filename = os.getenv("HOME") + "/sandbox/wishbone_interconnect.v"
			fileout = open(filename, "w")
			fileout.write(result)
		except IOError as err:
			print "File Error: " + str(err)

		self.assertEqual(len(result) > 0, True)
			


if __name__ == "__main__":
	unittest.main()