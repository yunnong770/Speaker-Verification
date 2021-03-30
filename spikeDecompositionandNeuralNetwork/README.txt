EE214 Final Project: Jonathan Brand, Yu Nong, and Jiazhang Song

%%The following files contain code that should be able to run implementations of the "Spike Detection" and "VGGVox Neural Network" methods for speaker identification.
The main file for testing each implementation is called "test_methods".  This file runs tests for both methods.
"fun_VggVoxNN" and "fun_SpikeDetection" are the core functions behind each method.  These are called in "test_methods".
Since spike detection is a somewhat strange method that may be difficult to understand, a "SpikeDecompositionDemo" file has been included with plenty of detail.

One of the requirements to run the VGGVox implementation is an installation and configuation of "MatConvNet", which is a foundation on which the neural network
relies.  Configuration of MatConvNet is a bit of a headache, and took us a long time to get right.  To save you the trouble of setting it up on your device,
we have included a file called "featureVGGVox_x1", which holds the feature dictionary for all the training and testing files in the original file list.  This
allows you to reproduce our results for the various combinations of clean and babble data, but you may be unable to run this code with the blind data.