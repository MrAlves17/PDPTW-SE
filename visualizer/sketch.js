let theCanvas;
let vehicleNumber;
let vehicleCapacity;
let customers = [];
let machines = [];
let steps = [];
/*
*	steps 		-> [step, step, step, ...]
*	steps[i] 	-> [truck, truck, truck, ...]
*	truck 		-> [int1, int2, int3, ...]
*				-> step -> int
*				-> truck -> int
*/
let tasksFileSelector;
let machinesFileSelector;
let labeltasksFileSelector;
let labelmachinesFileSelector;
let tasksData = undefined;
let machinesData = undefined;

let cartesian_width;
let cartesian_height;
let cartesian_padding = 40;
let truckContainer_width;
let truckContainer_heigth;
let fileSelector_width;
let fileSelector_height;
let timeScope_width;
let timeScope_height;
let timeScope_padding = 5;
let details_width;
let details_height;
let details_padding = 5;

let truckContainer;
let customerContainer;
let xlimit = 100;
let ylimit = 100;	
let zlimit = 0;
let current_step = 0;
let plottedCustomers = false;
let observedCustomer = -1;

function setup(){
	theCanvas = createCanvas(windowWidth, windowHeight);
	theCanvas.style("z-index", -1);
	frameRate(30);
	colorMode(HSL);
	textAlign(CENTER, CENTER);
	textSize(15);
	background(0);

	fileSelector_width = width/2;
	fileSelector_height = 50;

	setupFileSelectors();

	truckContainer_width = width/7;
	truckContainer_heigth = height - fileSelector_height;

	timeScope_width = width - truckContainer_width - timeScope_padding*2;
	timeScope_height = height/6 - timeScope_padding*2;

	details_width = width/5 - details_padding*2;
	details_height = height - fileSelector_height - timeScope_height - timeScope_padding*2 - details_padding*2;
	
	cartesian_width = width - truckContainer_width - details_width - details_padding*2 - cartesian_padding*2;
	cartesian_height = height - fileSelector_height - timeScope_height - timeScope_padding*2 - cartesian_padding*2;

	truckContainer = createDiv();
	truckContainer.size(truckContainer_width, truckContainer_heigth);
	truckContainer.position(0, fileSelector_height);
	truckContainer.style("overflow-y", "scroll");

	customerContainer = createDiv();
	customerContainer.size(cartesian_width, cartesian_height);
	customerContainer.position(truckContainer_width + cartesian_padding, fileSelector_height + cartesian_padding);
}

function draw(){
	background(0);
	stroke(120, 100, 50);
	// for(let i=0; i<=width; i+= width/16){
	// 	line(i, 0, i, height);
	// }
	// line(width/5, 0, width/5, height);
	// line(width/5, height - height/5, width, height - height/5);
	noFill(); stroke(0, 100, 50, 0.5); strokeWeight(1);
	rect(truckContainer_width + timeScope_padding, height - timeScope_padding, timeScope_width, -timeScope_height);
	if(tasksData != undefined){
		plotCustomers();
		if(!plottedCustomers){
			plotCustomersElements();
			plottedCustomers = true;
		}
	}
}

function readTasksData(){
	tasksData = tasksData.split("\n");
	tasksData.pop();
	for(let i=0; i<tasksData.length; i++){
		tasksData[i] = tasksData[i].split(',')
		for(let j=0; j<tasksData[i].length; j++){
			tasksData[i][j] = int(tasksData[i][j])
		}
	}
	for(let i=0; i<tasksData.length; i++){
		const c = new Customer(tasksData[i][0], tasksData[i][1], tasksData[i][2], tasksData[i][3], tasksData[i][8], tasksData[i][9]);
		customers.push(c);
		zlimit = max(zlimit, Number(c.z));
	}

	for(let i=0; i<customers.length; i++){
		customers[i].x = map(customers[i].x, 0, xlimit, 0, cartesian_width);
		customers[i].y = map(customers[i].y, 0, ylimit, 0, -cartesian_height);
	}
}

function readMachinesData(){
	machinesData = machinesData.split("\n");
	machinesData.pop();
	for(let i=0; i<machinesData.length; i++){
		machinesData[i] = machinesData[i].split(',');
		for(let j=0; j<machinesData[i].length; j++){
			machinesData[i][j] = int(machinesData[i][j])
		}
	}
	for(let i=0; i<machinesData.length; i++){
		const c = new Machine(machinesData[i][0], machinesData[i][1], machinesData[i][2], machinesData[i][3], machinesData[i][4]);
		machines.push(c);
	}

	for(let i=0; i<machines.length; i++){
		machines[i].x = map(machines[i].x, 0, xlimit, 0, cartesian_width);
		machines[i].y = map(machines[i].y, 0, ylimit, 0, -cartesian_height);
	}
}

function setupFileSelectors(){
	tasksFileSelector = createInput();
	machinesFileSelector = createInput();

	tasksFileSelector.attribute("type", "file");
	machinesFileSelector.attribute("type", "file");

	tasksFileSelector.attribute("id", "tasksFileSelector");
	machinesFileSelector.attribute("id", "machinesFileSelector");

	tasksFileSelector.size(fileSelector_width, fileSelector_height);	
	machinesFileSelector.size(fileSelector_width, fileSelector_height);

	tasksFileSelector.position(0, 0);
	machinesFileSelector.position(fileSelector_width, 0);

	tasksFileSelector.style("z-index", 1);
	machinesFileSelector.style("z-index", 1);

	tasksFileSelector.style("background-color", "#85C1E9");
	machinesFileSelector.style("background-color", "#76D7C4");

	tasksFileSelector.mouseOut(() => {tasksFileSelector.style("background-color", "#85C1E9");});
	machinesFileSelector.mouseOut(() => {machinesFileSelector.style("background-color", "#76D7C4");});
	
	tasksFileSelector.mouseOver(() => {tasksFileSelector.style("background-color", "#AED6F1");});
	machinesFileSelector.mouseOver(() => {machinesFileSelector.style("background-color", "#A3E4D7");});

	tasksFileSelector.show();
	machinesFileSelector.show();

	document.getElementById("tasksFileSelector").addEventListener("change", function(){
		const fr = new FileReader();
		fr.onload = function(){
			tasksData = this.result;
			readTasksData();
		};
		fr.readAsText(this.files[0]);
	});

	document.getElementById("machinesFileSelector").addEventListener("change", function(){
		const fr = new FileReader();
		fr.onload = function(){
			machinesData = this.result;
			readMachinesData();
		};
		fr.readAsText(this.files[0]);
	});
	
	// labels
		labeltasksFileSelector = createP("choose or drop tasks file");
		labelmachinesFileSelector = createP("choose or drop machines file");

		labeltasksFileSelector.style("background-color", document.getElementById("tasksFileSelector").backgroundColor);
		labelmachinesFileSelector.style("background-color", document.getElementById("machinesFileSelector").backgroundColor);

		labeltasksFileSelector.style("z-index", 2);
		labelmachinesFileSelector.style("z-index", 2);

		labeltasksFileSelector.style("margin", 0);
		labelmachinesFileSelector.style("margin", 0);

		// labeltasksFileSelector.size(tasksFileSelector.size().width, tasksFileSelector.size().height);
		// labelmachinesFileSelector.size(machinesFileSelector.size().width, machinesFileSelector.size().height);

		// labeltasksFileSelector.parent(tasksFileSelector);
		// labelmachinesFileSelector.parent(machinesFileSelector);

		// labeltasksFileSelector.position(width/2 - labeltasksFileSelector.size().width/2, 150);
		// labelmachinesFileSelector.position(width/2 - labelmachinesFileSelector.size().width/2, 350);

		labeltasksFileSelector.position(width/4 - labeltasksFileSelector.size().width/2, 0);
		labelmachinesFileSelector.position(3*width/4 - labelmachinesFileSelector.size().width/2, 0);

		labeltasksFileSelector.show();
		labelmachinesFileSelector.show();
}

function plotCustomers(){
	push();
	translate(truckContainer_width + cartesian_padding, height - timeScope_height - timeScope_padding*2 - cartesian_padding);
	noFill(); stroke(100); strokeWeight(1);
	line(0, 0, 0, -cartesian_height - cartesian_padding/2);
	line(0, 0, cartesian_width + cartesian_padding/2, 0);
	
	push();
	translate(0, -cartesian_height - cartesian_padding/2);
	rotate(QUARTER_PI);
	line(0, 0, 10, 0);
	rotate(-HALF_PI);
	line(0, 0, -10, 0);
	pop();
	push();
	translate(cartesian_width + cartesian_padding/2, 0);
	rotate(-QUARTER_PI);
	line(0, 0, 0, -10);
	rotate(HALF_PI);
	line(0, 0, 0, 10);
	pop();
	
	for(let i=0; i<=xlimit; i+=5){
		noFill(); stroke(100, 0.3); strokeWeight(1);
		let displayi = map(i, 0, xlimit, 0, cartesian_width)
		line(displayi, -cartesian_height, displayi, 5);
		fill(100); noStroke(100); strokeWeight(1);
		text(i, displayi, 20);
	}
	for(let i=0; i<=ylimit; i+=5){
		noFill(); stroke(100, 0.3); strokeWeight(1);
		let displayi = map(i, 0, ylimit, 0, -cartesian_height)
		line(-5, displayi, cartesian_width, displayi);
		fill(100); noStroke(100); strokeWeight(1);
		text(i, -20, displayi);
	}

	noFill(); stroke(0, 100, 50); strokeWeight(15);
	point(customers[0].x, customers[0].y);
	
	noFill(); stroke(0, 100, 100); strokeWeight(5);

	for(let i=1; i<customers.length; i++){
		if(observedCustomer == i){
			textSize(15)
		}else{
			textSize(10)
		}
		if(observedCustomer < 0 || customers[i].z == customers[observedCustomer].z){
			stroke((320-360/zlimit)/zlimit*customers[i].z + 360/zlimit, 100, 50)
			fill(255,255,255)
		}else{
			stroke(0,0,0,0)
			fill(0,0,0,0)
		}
		if (customers[i].pid == 0){
			text('p'+customers[i].id, customers[i].x, customers[i].y)
		}else{
			text('d'+(customers[i].id-(customers.length-1)/2), customers[i].x, customers[i].y)
		}
	}

	for(let i=0; i<machines.length; i++){
		if(observedCustomer<0 || customers[observedCustomer].z >= machines[i].lz && customers[observedCustomer].z <= machines[i].hz){
			stroke(0, 100, 100)
		}else{
			stroke(0,0,0,0)
		}
		strokeWeight(10);
		point(machines[i].x, machines[i].y);
	}
	pop();
}

function plotCustomersElements(){
	push();
	for(let i=0; i<customers.length; i++){
		let customerDiv = createDiv();
		customerDiv.parent(customerContainer);
		customerDiv.size(10, 10);
		customerDiv.position(customers[i].x-5, map(customers[i].y, 0, -cartesian_height, cartesian_height, 0)-5);
		customerDiv.mouseOver(() => {observedCustomer = customers[i].id});
		customerDiv.mouseOut(() => {observedCustomer = -1});
	}
	pop();
}