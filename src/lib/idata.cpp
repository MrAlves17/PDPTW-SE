#include "idata.hpp"
std::string extract_inst_name(std::string filename){
	int j = filename.size()-1;
	while(filename[j] != '.'){
		j--;
	}
	j--;
	int i = j;	
	while(filename[i] != '/'){
		i--;
	}
	i++;
	return filename.substr(i,j-i+1);
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

void IDATA::read_input(PARAMETERS& param) {
	std::ifstream file;
	file.open(param.filename);
	if (!file) exit(1);

	this->instance_name = extract_inst_name(param.filename);

	std::string expletive;
	file >> expletive;
	assert(expletive == "VEHICLES");
	
	int qtt_vehicles;
	file >> qtt_vehicles;

	for(int i=0; i<3; i++){
		file >> expletive;
	}

	assert(expletive == "CAPACITY");
	int id_v, cap;
	for(int i=0; i<qtt_vehicles; i++){
		file >> id_v >> cap;
		VEHICLE vehicle(id_v, cap);
		this->vehicles.push_back(vehicle);
	}

	file >> expletive;
	assert(expletive == "TASKS");
	
	int qtt_tasks;
	file >> qtt_tasks;
	for(int i=0; i<11; i++){
		file >> expletive;
	}
	assert(expletive == "DID");

	int id_c, dem, p_id, d_id;
	long double x, y, z, earliest, latest, servtime;
	for(int i=0; i<qtt_tasks; i++){
		file >> id_c >> x >> y >> z >> dem >> earliest >> latest >> servtime >> p_id >> d_id;
		CUSTOMER cust(id_c, x, y, z, dem, earliest, latest, servtime, p_id, d_id);
		this->customers.push_back(cust);
	}

	file >> expletive;
	assert(expletive == "MACHINES");
	
	int qtt_machines;
	file >> qtt_machines;
	for(int i=0; i<7; i++){
		file >> expletive;
	}

	assert(expletive == "SPEED");

	int id_m;
	long double lz, hz, speed;
	for(int i=0; i<qtt_machines; i++){
		file >> id_m >> lz >> hz >> x >> y >> speed;
		MACHINE mach(id_m, lz, hz, x, y, speed);
		this->machines.push_back(mach);
	}

	this->qtt_vehicles = this->vehicles.size();
	this->qtt_customers = this->customers.size();
	this->qtt_machines = this->machines.size();

	this->CalculateDistances();
	file.close();
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
