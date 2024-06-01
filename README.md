# SnnAccelerator Master Thesis project

Repository for the Master thesis of Jan Calduch Isaksen on "Interface Requirements for Neuromorphic Coprocessors in Embedded Systems: Design and study of an interface for integrating tinyODIN as a SoC coprocessor".

Tis repository contains the hardware and software codes used to complete the master thesis. This includes the hardware RTL codes of the modules that compose the interface and the testbenhces used to verify them, as well as the software codes to simulate tinyODIN in C and in Python, and to pre-process the MNKST dataset in Python. There is an additional folder, data, with .txt files containing the pre-processed and encoded MNIST images together. 

tinyODIN is an SNN processor based on ODIN, both designed by Charlotte Frenkel and found on: https://github.com/ChFrenkel/tinyODIN and https://github.com/ChFrenkel/ODIN. For more information see [C. Frenkel, M. Lefebvre, J.-D. Legat and D. Bol, "A 0.086-mm² 12.7-pJ/SOP 64k-Synapse 256-Neuron Online-Learning Digital Spiking Neuromorphic Processor in 28-nm CMOS," IEEE Transactions on Biomedical Circuits and Systems, vol. 13, no. 1, pp. 145-158, 2019.]
