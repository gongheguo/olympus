import unittest
import os
import sys
import json
import sapfile
import saputils
import sap_graph_manager as gm

class Test (unittest.TestCase):
	"""Unit test for gen_drt.py"""


	def setUp(self):
		self.dbg = False
		self.vbs = False
		if "SAPLIB_VERBOSE" in os.environ:
			if (os.environ["SAPLIB_VERBOSE"] == "True"):
				self.vbs = True

		if "SAPLIB_DEBUG" in os.environ:
			if (os.environ["SAPLIB_DEBUG"] == "True"):
				self.dbg = True

		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		json_string = ""
		try:
			#open up the specified JSON project config file
			filein = open (file_name)
			#copy it into a buffer
			json_string = filein.read()
			filein.close()
		except IOError as err:
			print("File Error: " + str(err))
			return False

		self.project_tags = json.loads(json_string)

		if self.dbg:
			print "loaded JSON file"

		#generate graph
		self.sgm = gm.SapGraphManager()

		return

	def test_graph_add_node(self):
		if self.dbg:
			print "generating host interface node"

		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		#get the size of the graph
		size = self.sgm.get_size()
		if self.dbg:
			print "number of nodes: " + str(size)

		self.assertEqual(size, 1)	

	def test_clear_graph(self):
		if self.dbg:
			print "generating host interface node"

		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		#get the size of the graph
		size = self.sgm.get_size()
		if self.dbg:
			print "number of nodes: " + str(size)

		self.sgm.clear_graph()

		size = self.sgm.get_size()
		self.assertEqual(size, 0)	


	def test_graph_add_slave_node(self):
		if self.dbg:
			print "generating host interface node"

		self.sgm.add_node(	"gpio", 
							gm.Node_Type.slave,
							gm.Slave_Type.peripheral,
							slave_index=1,
							debug=self.dbg)

		gpio_name = gm.get_unique_name(	"gpio", 
										gm.Node_Type.slave,
										gm.Slave_Type.peripheral,
										slave_index = 1)

		if self.dbg:
			print "unique name: " + gpio_name
		#get the size of the graph
		size = self.sgm.get_size()
		if self.dbg:
			print "number of nodes: " + str(size)

		self.assertEqual(size, 1)	


	def test_graph_remove_node(self):
		if self.dbg:
			print "adding two nodes"


		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		self.sgm.add_node("master", gm.Node_Type.master)



		size = self.sgm.get_size()
		if self.dbg:
			print "number of nodes: " + str(size)

		self.assertEqual(size, 2)	

		#remove the uart node
		unique_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)

		self.sgm.remove_node(unique_name)

		size = self.sgm.get_size()
		if self.dbg:
			print "number of nodes: " + str(size)

		self.assertEqual(size, 1)	


	def test_get_node_names(self):
		if self.dbg:
			print "adding two nodes"

		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		self.sgm.add_node("master", gm.Node_Type.master)

		names = self.sgm.get_node_names()
		

		uart_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)
		master_name = gm.get_unique_name("master", gm.Node_Type.master)

		self.assertIn(uart_name, names)
		self.assertIn(master_name, names)

	def test_get_nodes(self):
		if self.dbg:
			print "adding two nodes"

		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		self.sgm.add_node("master", gm.Node_Type.master)

		graph_dict = self.sgm.get_nodes_dict()
		

		uart_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)
		master_name = gm.get_unique_name("master", gm.Node_Type.master)

		if self.dbg:
			print "dictionary: " + str(graph_dict)

		self.assertIn(uart_name, graph_dict.keys())
		self.assertIn(master_name, graph_dict.keys())
		

	def test_connect_nodes(self):
		if self.dbg:
			print "adding two nodes"

		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		self.sgm.add_node("master", gm.Node_Type.master)



		uart_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)
		master_name = gm.get_unique_name("master", gm.Node_Type.master)

		#get the number of connections before adding a connection	
		num_of_connections = self.sgm.get_number_of_connections()
		self.assertEqual(num_of_connections, 0)

		self.sgm.connect_nodes(uart_name, master_name)
		#get the number of connections after adding a connection	
		num_of_connections = self.sgm.get_number_of_connections()

		self.assertEqual(num_of_connections, 1)

	def test_disconnect_nodes(self):
		if self.dbg:
			print "adding two nodes"

		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		self.sgm.add_node("master", gm.Node_Type.master)



		uart_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)
		master_name = gm.get_unique_name("master", gm.Node_Type.master)

		#get the number of connections before adding a connection	
		num_of_connections = self.sgm.get_number_of_connections()
		self.assertEqual(num_of_connections, 0)

		self.sgm.connect_nodes(uart_name, master_name)
		#get the number of connections after adding a connection	
		num_of_connections = self.sgm.get_number_of_connections()

		self.assertEqual(num_of_connections, 1)

		self.sgm.disconnect_nodes(uart_name, master_name)
		num_of_connections = self.sgm.get_number_of_connections()
		self.assertEqual(num_of_connections, 0)


	def test_get_node_data(self):
		if self.dbg:
			print "adding a nodes"

		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		uart_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)

		node = self.sgm.get_node(uart_name)
		self.assertEqual(node.name, "uart")

	def test_set_parameters(self):
		"""
		set all the parameters aquired from a module
		"""
		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		uart_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)

		file_name = os.getenv("SAPLIB_BASE") + "/hdl/rtl/wishbone/host_interface/uart/uart_io_handler.v"
		parameters = saputils.get_module_tags(filename = file_name, bus="wishbone")

		self.sgm.set_parameters(uart_name, parameters)
		parameters = None
		if self.dbg:
			print "parameters: " + str(parameters)

		parameters = self.sgm.get_parameters(uart_name)

		if self.dbg:
			print "parameters: " + str(parameters)

		self.assertEqual(parameters["module"], "uart_io_handler")


	def test_bind_pin_to_port(self):
		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		uart_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)

		file_name = os.getenv("SAPLIB_BASE") + "/hdl/rtl/wishbone/host_interface/uart/uart_io_handler.v"
		parameters = saputils.get_module_tags(filename = file_name, bus="wishbone")

		self.sgm.set_parameters(uart_name, parameters)
		
		self.sgm.bind_pin_to_port(uart_name, "phy_uart_in", "RX") 

		parameters = None
		parameters = self.sgm.get_parameters(uart_name)

		#print "Dictionary: " + str(parameters["ports"]["phy_uart_in"])
		self.assertEqual(parameters["ports"]["phy_uart_in"]["port"], "RX")

		



if __name__ == "__main__":
	unittest.main()

