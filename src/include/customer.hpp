#ifndef customer_class
#define customer_class

class CUSTOMER{
	public:
	int id, demand, z;
	long double x, y, earliest, latest, servtime;
	int p_id, d_id;

	CUSTOMER(){
		id = -1;
		x = 0;
		y = 0;
		z = 0;
		demand = -1;
		earliest = -1;
		latest = -1;
		servtime = -1;
		p_id = 0;
		d_id = 0;
	}

	CUSTOMER(int id_, long double x_, long double y_, int z_, int demand_, long double earliest_, long double latest_, long double servtime_, int p_id_, int d_id_){
		id = id_;
		x = x_;
		y = y_;
		z = z_;
		demand = demand_;
		earliest = earliest_;
		latest = latest_;
		servtime = servtime_;
		p_id = p_id_;
		d_id = d_id_;
	}

	bool operator <(const CUSTOMER& rhs) {
		return demand < rhs.demand;
	}
};

#endif