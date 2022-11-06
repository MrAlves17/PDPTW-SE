#include "parameters.hpp"
#include "idata.hpp"
#include <getopt.h>
#include <string>

void show_help(const char *name) {
	fprintf(stderr, "\
usage: %s <parameters>\n\
	-h,     --help                      show help.\n\
	-f,  	--filename <string>			set filename.\n", name);
	exit(-1);
}

void read_args(const int argc, char* argv[], PARAMETERS& param) {
	int opt;
	/*
		https://daemoniolabs.wordpress.com/2011/10/07/usando-com-as-funcoes-getopt-e-getopt_long-em-c/
		https://linux.die.net/man/3/getopt_long
	*/
	const option options[] = {
		{"help"                 , no_argument       , 0 , 'h' },
		{"filename"				, required_argument , 0 , 'f' },
		{0                      , 0                 , 0 ,  0  },
	};

	if (argc < 2) {
		show_help(argv[0]);
	}

	while( (opt = getopt_long(argc, argv, "hf:", options, NULL)) > 0 ) {
		switch ( opt ) {
			case 'h': /* -h ou --help */
				show_help(argv[0]);
				break;
			case 'f': /* -f ou --filename */
				param.filename = optarg;
				break;
			default:
				fprintf(stderr, "Opcao invalida ou faltando argumento: `%c'\n", optopt);
				exit(-1);
		}
	}
}



int32_t main(int argc, char *argv[]){
	// printf("start!\n");
	// std::ios::sync_with_stdio(false); std::cin.tie(0);

	PARAMETERS param = PARAMETERS();
	IDATA idata;

	read_args(argc, argv, param);

	idata.read_input(param);

	idata.print_input();

	return 0;
}