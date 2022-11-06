#ifndef vehicle_class
#define vehicle_class

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

	bool operator <(const VEHICLE& rhs) {
		return capacity < rhs.capacity;
	}
};

#endif