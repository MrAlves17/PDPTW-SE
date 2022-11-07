#ifndef vehicle_class
#define vehicle_class

#include <vector>

class VEHICLE{
	public:
	int id;
	int capacity;

	VEHICLE(){
		id = -1;
		capacity = 0;
	}

	VEHICLE(int id_, int capacity_){
		id = id_;
		capacity = capacity_;
	}

	VEHICLE(std::vector<std::string> vehicle){
		id = std::stold(vehicle[0]);
		capacity = std::stold(vehicle[1]);
	}

	bool operator <(const VEHICLE& rhs) {
		return capacity < rhs.capacity;
	}
};

#endif