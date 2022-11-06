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

	bool operator <(const MACHINE& rhs) {
		return speed < rhs.speed;
	}
};

#endif