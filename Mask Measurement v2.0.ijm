//masks="Training Set_Simple Segmentation__.tif";
//training="Training Set.tif";
//roiDir="C:\\Temp\\"
run("Options...", "iterations=1 count=1 black");

fs=File.separator;
roiManager("Associate", "false");
roiManager("Centered", "false");
roiManager("UseNames", "false");


dir=getDirectory("Select Source Directory");
list=getFileList(dir);
roiDir=dir+"ROIs"+fs;
File.makeDirectory(roiDir);
saveDir=dir+"Output"+fs;
File.makeDirectory(saveDir);

Dialog.create("Analysis Settings");
Dialog.addNumber("How Many Pixels is 10mm?", 0);
Dialog.addNumber("Size Cutoff for Positive Count (mm^2)", 0.5);
Dialog.addNumber("Circularity Cutoff for Positive Count (0-1.0)", 0.3);
Dialog.addNumber("Live Coral Mask Number", 1);
Dialog.addNumber("Starting Point of Background Ring from Coral (px)",3);
Dialog.addNumber("Width of Background Ring (px)",5); 

Dialog.show();

howLong10mm=Dialog.getNumber();
sizeCutoff=Dialog.getNumber();
circCutoff=Dialog.getNumber();
maskNumber=Dialog.getNumber();
ringStart=Dialog.getNumber();
ringWidth=Dialog.getNumber();


tableTitle="[Coral Analysis]";
if (isOpen("Coral Analysis")){
	print("Table already open");}
	
	else{
		
		run("Table...", "name="+tableTitle+" width=1200 height=250");
		print(tableTitle, "\\Headings:Image Name\tLive Coral ID Number\tArea (mm^2)\tPerimeter (mm)\tCoral Red Mean\tCoral Green Mean\tCoral Blue Mean\tBackground Red Mean\tBackground Green Mean\tBackground Blue Mean\tCoral Hue Mean\tCoral Saturation Mean\tCoral Brightness Mean\tBackground Hue Mean\tBackground Saturation Mean\tBackground Brightness Mean");
	}

	setBatchMode(true);
	fileCount=1;
roiManager("reset");
for(i=0;i<list.length;i++){
	roiManager("reset");
	run("Set Measurements...", "area mean perimeter display redirect=None decimal=3");
	fileName=dir+list[i];
	if(endsWith(fileName, "tif")){
		print("Processing file "+fileCount+" of "+(list.length/2));
		open(fileName);
		origImage=getTitle();
		saveName=File.getNameWithoutExtension(fileName);
		maskName=dir+list[i+1];
		open(maskName);
		maskImage=getTitle();
		print(origImage);
		print(maskImage);

		selectWindow(maskImage);
		setThreshold(maskNumber,maskNumber);
		run("Clear Results");
		run("Measure");

		if(nResults>=1){
			run("Create Mask");

			selectWindow("mask");
			run("Set Scale...", "distance="+howLong10mm+" known=10 unit=mm");

			run("Analyze Particles...", "size="+sizeCutoff+"-Infinity circularity="+circCutoff+"-1.00 show=Masks display clear");

			if(nResults>=1){

				selectWindow("Mask of mask");
				rename("Live Mask");
				run("Invert LUT");
				run("Fill Holes");
				
				selectWindow("mask");
				close();
				//selectWindow("Live Mask");
				//run("Duplicate...", "title=[For Dilate]");
				//run("Options...", "iterations="+(ringStart+ringWidth)+" count=1 black do=Dilate");
				
				//selectWindow("Live Mask");
				//run("Duplicate...", "title=[For Dilate2]");
				//run("Options...", "iterations="+ringStart+" count=1 black do=Dilate");
				
				//imageCalculator("Subtract create", "For Dilate","For Dilate2");
				//selectWindow("Result of For Dilate");
				//rename("Background Ring");
				
				//selectWindow("For Dilate");
				//close();
				//selectWindow("For Dilate2");
				//close();
				
				selectWindow(origImage);
				run("Duplicate...", "title=[For HSB]");
				selectWindow(origImage);
				run("RGB Stack");
				run("Make Composite", "display=Composite");

				selectWindow("For HSB");
				wait(200);
				run("HSB Stack");
				wait(200);
				
				selectWindow("Live Mask");
				getDimensions(width, height, channels, slices, frames);
				run("Analyze Particles...", "add");
				roiManager("Save", roiDir+origImage+" - Live Rois.zip");
	
				numROIs=roiManager("count");
				//roiManager("reset");
				//wait(200);
				
				//selectWindow("Background Ring");
				//run("Analyze Particles...", "add");
				//roiManager("Save", roiDir+origImage+" - Ring Rois.zip");
				
				//roiManager("reset");
				//wait(200);
		
				//print(numRois);

				newImage("Background Ring", "8-bit black", width, height, 1);

				for(r=0;r<numROIs;r++){
					print("Measuring Coral "+(r+1)+" of "+numROIs);
					run("Set Measurements...", "area mean perimeter display redirect=["+origImage+"] decimal=3");
					selectWindow("Live Mask");
					//roiManager("Open", roiDir+origImage+" - Live Rois.zip");
					
					selectWindow(origImage);
					setSlice(1);
					run("Set Scale...", "distance="+howLong10mm+" known=10 unit=mm");
				
					selectWindow("Live Mask");
					roiManager("Select", r);
					run("Analyze Particles...", "display");
					coralArea=getResult("Area");
					coralPerimeter=getResult("Perim.");
					coralRed=getResult("Mean");
					selectWindow(origImage);
					setSlice(2);
				
					selectWindow("Live Mask");
					run("Analyze Particles...", "display");
					coralGreen=getResult("Mean");
					selectWindow(origImage);
					setSlice(3);
		
					selectWindow("Live Mask");
					run("Analyze Particles...", "display");
					coralBlue=getResult("Mean");

					run("Set Measurements...", "area mean perimeter display redirect=[For HSB] decimal=3");

					selectWindow("For HSB");
					setSlice(1);
					run("Set Scale...", "distance="+howLong10mm+" known=10 unit=mm");

					selectWindow("Live Mask");
					roiManager("Select", r);
					run("Analyze Particles...", "display");
					coralHue=getResult("Mean");
					selectWindow("For HSB");
					setSlice(2);
				
					selectWindow("Live Mask");
					run("Analyze Particles...", "display");
					coralSaturation=getResult("Mean");
					selectWindow("For HSB");
					setSlice(3);
		
					selectWindow("Live Mask");
					run("Analyze Particles...", "display");
					coralBrightness=getResult("Mean");
					
					selectWindow("Live Mask");
					roiManager("select", r);
					run("Enlarge...", "enlarge="+(ringStart+ringWidth)+" pixel");
					run("Create Mask");
					selectWindow("Mask");
					rename("Outer Ring");

					selectWindow("Live Mask");
					roiManager("select", r);
					run("Enlarge...", "enlarge="+ringStart+" pixel");
					run("Create Mask");
					selectWindow("Mask");
					rename("Inner Ring");

					imageCalculator("Subtract", "Outer Ring","Inner Ring");
					selectWindow("Inner Ring");
					close();

					run("Set Measurements...", "area mean perimeter display redirect=["+origImage+"] decimal=3");
					
					selectWindow(origImage);
					setSlice(1);
					selectWindow("Outer Ring");
					run("Analyze Particles...", "display");
					backgroundRed=getResult("Mean");
					selectWindow(origImage);
					setSlice(2);
					selectWindow("Outer Ring");
					run("Analyze Particles...", "display");
					backgroundGreen=getResult("Mean");
					selectWindow(origImage);					
					setSlice(3);
					selectWindow("Outer Ring");
					run("Analyze Particles...", "display");
					backgroundBlue=getResult("Mean");

					run("Set Measurements...", "area mean perimeter display redirect=[For HSB] decimal=3");
					
					selectWindow("For HSB");
					setSlice(1);
					selectWindow("Outer Ring");
					run("Analyze Particles...", "display");
					backgroundHue=getResult("Mean");
					selectWindow("For HSB");
					setSlice(2);
					selectWindow("Outer Ring");
					run("Analyze Particles...", "display");
					backgroundSaturation=getResult("Mean");
					selectWindow("For HSB");					
					setSlice(3);
					selectWindow("Outer Ring");
					run("Analyze Particles...", "display");
					backgroundBrightness=getResult("Mean");

					imageCalculator("Add", "Background Ring","Outer Ring");
					selectWindow("Outer Ring");
					close();

					
					print(tableTitle, origImage+"\t"+(r+1)+"\t"+coralArea+"\t"+coralPerimeter+"\t"+coralRed+"\t"+coralGreen+"\t"+coralBlue+"\t"+backgroundRed+"\t"+backgroundGreen+"\t"+backgroundBlue+"\t"+coralHue+"\t"+coralSaturation+"\t"+coralBrightness+"\t"+backgroundHue+"\t"+backgroundSaturation+"\t"+backgroundBrightness);

				
				}

				//roiManager("reset");
				selectWindow("Background Ring");
				run("Select None");
				run("Subtract...", "value=150");
				run("Select All");
				run("Copy");
				selectImage(origImage);
				run("Add Slice", "add=channel");
				Stack.setChannel(4);
				run("Paste");
				run("Cyan");
				run("RGB Color");
				selectWindow(origImage+" (RGB)");
				roiManager("show all with labels");
				run("Flatten");
				selectWindow(origImage+" (RGB)-1");

				saveAs("Tiff", saveDir+saveName+" - Live Selection.tif");
				run("Close All");

				selectWindow("Results");
				run("Close");
			
			}
			run("Close All");
			}}
			i=i+1;
			fileCount=fileCount+1;
			
			
			}

selectWindow("Coral Analysis");
saveAs("Results", saveDir+"Coral Analysis.csv");
run("Close");

print("FINISHED!!!");

