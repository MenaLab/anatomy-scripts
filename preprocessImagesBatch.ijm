"E:/Lab Data/GABA Antero Synapto + Fast Blue/GABA Antero Synapto + Fast Blue/processed/431D/431.1.2.1_Stack.tif"/* Macro to split and save multi-channel data in files, 
 * using Channel Name (e.g. "cy5") appended to each channel's file name
 * Input folder: directory in which all files you want to split and save are located
 * Output folder: directory at which you want split files to be saved (as tiffs)
 * suffix: ".oib" to get only the raw images in the input directory
 * 
 * 3/14/21: This macro currently checks all the subfolders of the input folder, it might 
 * be a good idea to put an end to that some time
 * 4/1/21: It's now asking if you want to go on processing the subfolders and if not, it stops there
 * 4/6/21: Added scale bar (1000um) and background subtraction
 */


// Setup Macro Extensions
run("Bio-Formats Macro Extensions");

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".oib") suffix

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if (File.isDirectory(input + File.separator + list[i])) {
			if (getBoolean("Process subfolders in the input directory?")) {
				processFolder(input + File.separator + list[i]);}
			else {
				print("not processing subfolder " + list[i]);
			}
		}
			
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
	print("done processing the folder: " + input);
}

function processFile(input, output, file) {
	// Import file via the excellent Bio-Formats
	id = input + File.separator + file;
	Ext.setId(id);
	Ext.getEffectiveSizeC(sizeC);
//	print(sizeC);

	run("Bio-Formats Importer", "open=[" + id + "] scale=5% color_mode=Composite rois_import=[ROI manager] split_channels view=Hyperstack stack_order=XYCZT");
	name = file;
	// Progress update
	print("Processing: " + file);
	// Cycle through the channels (image windows), adjust, and save as tiff
	for (i=0; i < sizeC; i++) {
		selectWindow(name + " - C=" + i);
		openID = getImageID();
//		print(sizeC);
		// use DyeName to get the Channel Name
		channelName = getInfo("[Channel " + (i+1) + " Parameters] DyeName");
//		print(i + "-" + channelName);

		// sum slices across Z-planes
		sizeZ = getInfo("SizeZ");
		if (sizeZ > 1) {
			run("Z Project...", "projection=[Sum Slices]");
		}
		run("Color Balance...");
		run("Enhance Contrast", "saturated=0.10");


		// Assign colors to channels from image metadata
		if (indexOf(channelName, "488") >= 0) {
			channel = "Green";
		} else if (indexOf(channelName, "EYFP") >= 0) {
			channel = "Green";
		} else if (indexOf(channelName, "Cy3") >= 0) {
			channel = "Red";
		} else if (indexOf(channelName, "Cy5") >= 0) {
			channel = "Grays";
		} else if (indexOf(channelName, "DAPI") >= 0) {
			if (indexOf(name, "FB") >= 0) {
				channel = "Cyan";
			} else {
				channel = "Magenta";}
		} else if (indexOf(channelName, "405") >= 0) {
			if (indexOf(name, "FB") >= 0) {
				channel = "Cyan";
			} else {
				channel = "Magenta";}
		} else {
			channel = "Grays";}

		run("16-bit");	
		run(channel);

		// convert image to RGB Color
		run("RGB Color");

		// subtract background
//		run("Subtract Background...", "rolling=30 separate sliding stack");
		
		// add scale bar
		// TO DO: write it so that it adds appropriate scale bars (e.g. <500um for 20x images vs 1000um for 10x etc)
		run("Scale Bar...", "width=1000 height=32 font=112 color=White background=None location=[Lower Right] bold label");
		
//		if isEmpty(channelName)
		// save each channel separately as tiff
		print("saving: " + channelName);
		saveAs("tiff", output + File.separator + file + "_" + channelName);
	}
	
//	print("Saving to: " + output);
	
	run("Close All");
}
