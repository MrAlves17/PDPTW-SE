#include "idata.hpp"
std::string extract_inst_name(std::string instdir){
	int j = instdir.size()-2;
	int i = j;	
	while(instdir[i] != '/'){
		i--;
	}
	i++;
	return instdir.substr(i,j-i+1);
}

void IDATA::CalculateDistances() {
	this->distance.resize(this->qtt_customers);
	for (int i = 0; i < this->qtt_customers; i++) {
		this->distance[i].resize(this->qtt_customers);
		for (int j = 0; j < this->qtt_customers; j++) {
			this->distance[i][j] = sqrt((this->customers[i].x - this->customers[j].x) * (this->customers[i].x - this->customers[j].x) + (this->customers[i].y - this->customers[j].y) * (this->customers[i].y - this->customers[j].y));
		}
	}
}

std::vector<std::string> split(std::string line){
	std::string delimiter = ",";
	std::vector<std::string> words;

	size_t pos;
	while ((pos = line.find(delimiter)) != std::string::npos) {
		words.push_back(line.substr(0, pos));
		line.erase(0, pos + delimiter.length());
	}
	words.push_back(line);

	return words;
}

void IDATA::read_csv(std::string instdir, std::string name){
	std::ifstream file;
	file.open(instdir+name+".csv");
	if (!file) exit(1);

	std::string line;
	while(std::getline(file, line)){
		std::vector<std::string> words = split(line);
		if(name == "vehicles"){
			VEHICLE vehicle(words);
			this->vehicles.push_back(vehicle);
		}else if(name == "tasks"){
			CUSTOMER customer(words);
			this->customers.push_back(customer);
		}else if(name == "machines"){
			MACHINE machine(words);
			this->machines.push_back(machine);
		}else{
			exit(-1);
		}
	}
	file.close();
}

void IDATA::read_input(PARAMETERS& param) {

	this->instance_name = extract_inst_name(param.instdir);

	read_csv(param.instdir, "vehicles");
	read_csv(param.instdir, "tasks");
	read_csv(param.instdir, "machines");

	this->qtt_vehicles = this->vehicles.size();
	this->qtt_customers = this->customers.size();
	this->qtt_machines = this->machines.size();

	this->CalculateDistances();
}


void IDATA::print_input(){
	std::cout << this->instance_name << '\n';
	std::cout << this->qtt_vehicles << ' ' << this->qtt_customers << ' ' << this->qtt_machines  << ' ' << '\n';
	for (VEHICLE vehicle : this->vehicles) {
		std::cout << vehicle.id << ' ' << vehicle.capacity << '\n';
	}
	std::cout  << '\n';
	for (CUSTOMER cust : this->customers) {
		std::cout << cust.id << ' ' << cust.x << ' ' << cust.y << ' ' << cust.z << ' ' << cust.demand << ' ' << cust.earliest << ' ' << cust.latest << ' ' << cust.servtime << ' ' << cust.p_id << ' ' << cust.d_id << '\n';
	}
	std::cout  << '\n';
	for (MACHINE mach : this->machines) {
		std::cout << mach.id << ' ' << mach.x << ' ' << mach.y << ' ' << mach.lz << ' ' << mach.hz << ' ' << mach.speed << '\n';
	}
}

void IDATA::print_distances(){
	std::cout << "\nBeginning of distance matrix:\n";
	for (int i = 0; i < std::min(10, this->qtt_customers); ++i) {
		for (int j = 0; j < std::min(10, this->qtt_customers); ++j) {
			std::cout << std::fixed << std::setprecision(2) << std::setw(5) << this->distance[i][j] << ' ';
		}
		std::cout << '\n';
	}
}
