#ifndef idata_class
#define idata_class

#include "customer.hpp"
#include "parameters.hpp"
#include "vehicle.hpp"
#include "machine.hpp"
#include <iostream>
#include <iomanip>
#include <fstream>
#include <cassert>
#include <cmath>
#include <algorithm>
#include <vector>
#include <set>
#include <string>

class IDATA{
	public:
	std::string instance_name;
	int qtt_vehicles;
	std::vector<VEHICLE> vehicles;
	int qtt_customers;
	std::vector<CUSTOMER> customers;
	int qtt_machines;
	std::vector<MACHINE> machines;	
	std::vector< std::vector<long double> > distance;

	void read_csv(std::string, std::string);
	void read_input(PARAMETERS& param);
	static std::vector<int> ids_by_closest_to_depot(const IDATA&);
	static std::vector<int> ids_by_latest_deadline(const IDATA&);
	void print_input();
	void print_distances();
	void CalculateDistances();
};

#endif