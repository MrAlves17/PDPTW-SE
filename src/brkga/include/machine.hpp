#ifndef machine_class
#define machine_class

class MACHINE{
	public:
	int id;
	long double x, y, lz, hz, speed;

	MACHINE(){
		id = -1;
		lz = 0;
		hz = 0;
		x = 0;
		y = 0;
		speed = 0;
	}

	MACHINE(int id_, long double lz_, long double hz_, long double x_, long double y_, long double speed_){
		id = id_;
		lz = lz_;
		hz = hz_;
		x = x_;
		y = y_;
		speed = speed_;
	}

	MACHINE(std::vector<std::string> machine){
		id = std::stold(machine[0]);
		lz = std::stold(machine[1]);
		hz = std::stold(machine[2]);
		x = std::stold(machine[3]);
		y = std::stold(machine[4]);
		speed = std::stold(machine[5]);
	}

	bool operator <(const MACHINE& rhs) {
		return speed < rhs.speed;
	}
};

#endif