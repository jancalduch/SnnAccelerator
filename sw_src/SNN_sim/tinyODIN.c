#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>
#include <inttypes.h>
#include <stdbool.h>
#include <string.h>

// Number of MNIST images to process
#define DATASET_SIZE 10000

// MNIST images have been resized to 16x16
#define IMAGE_SIZE 256

// Each pixel on MNIST is a value from 0 to 255, stored as integers
#define PIXEL_MAX_VALUE 255

// SNN parameters
#define IL_neurons 256
#define OL_neurons 10
#define SPIKE_THRESHOLD 222


void print_array(int array[]){
  printf("[");
  for (int i = 0; i < IMAGE_SIZE; i++) {
    printf("%d", array[i]);
    if (i < IMAGE_SIZE - 1) {
      printf(","); 
    }
  }
  printf("]\n\n");
}

void read_2d_image_array_from_file(const char *file_path, int rows, int columns, int array[DATASET_SIZE][IMAGE_SIZE]) {

  // Open a file
  FILE *fp = fopen(file_path, "r");
  if (fp == NULL){
    printf("Error opening file: %s\n", file_path);
    return;
  }

  // Read the file and fill the 2D array
  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < columns; j++) {
      fscanf(fp, "%d", &array[i][j]);
    }
  }
  
  // Close the file
  fclose(fp);
}

void read_2d_weight_array_from_file(const char *file_path, int rows, int columns, int array[IL_neurons][OL_neurons]) {

  // Open a file
  FILE *fp = fopen(file_path, "r");
  if (fp == NULL){
    printf("Error opening file: %s\n", file_path);
    return;
  }

  // Read the file and fill the 2D array
  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < columns; j++) {
      fscanf(fp, "%d", &array[i][j]);
    }
  }
  
  // Close the file
  fclose(fp);
}

void read_array_from_file(const char *file_path, int size, int array[DATASET_SIZE]) {
  // Open the file with the pre-processed MNIST images in read mode
  FILE *fp = fopen(file_path, "r");
  if (fp == NULL){
    printf("Error opening file: %s\n", file_path);
    return;
  }

  // Read the file and fill the array
  for (int i = 0; i < size; i++) {
    fscanf(fp, "%d", &array[i]);
  }
  
  // Close the file
  fclose(fp);
}

/* ROC encode based on Counting sort sorting algorithm. Linear time and space 
  compelxity. */
void ROC_encode(int input_array[], int output_array[]) {

  // Array to store frequency of each intensity value
  int frequency[PIXEL_MAX_VALUE+1] = {0};

  // Calculate frequency of each intensity value
  for (int pixelID = 0; pixelID < IMAGE_SIZE; pixelID++) {
    frequency[input_array[pixelID]]++;
  }

  // Calculate cumulative sum of frequencies
  for (int intensity = PIXEL_MAX_VALUE - 1; intensity >= 0; intensity--) {
    frequency[intensity] += frequency[intensity + 1];
  }

  // Fill output array using counting sort
  for (int pixelID = IMAGE_SIZE - 1; pixelID >= 0; pixelID--) {
    int intensity = input_array[pixelID];
    // Store the value to the output array
    output_array[frequency[intensity] - 1] = pixelID;
    frequency[intensity]--;
  }

  // print_array(output_array);
}

int tinyODIN(int image[], int weights[IL_neurons][OL_neurons]){
  
  int state[OL_neurons] = {0};  // State of each output neuron            

  /* Loop trough the encoded image and process each spike event until an output
    neuron generates a spike. Return the output spike as it is the inferred 
    digit. */
  for (int i = 0; i < IMAGE_SIZE; i++) {
    int IL_neuron = image[i]; // IL neuron that spikes

    /* Resolve the spike event by updating each OL neuron with the weight 
    between that neuron and the IL neuron. Then, check if the firing condition 
    is met. */
    for (int OL_neuron = 0; OL_neuron < OL_neurons; OL_neuron++) {
      state[OL_neuron] += weights[IL_neuron][OL_neuron];
      if (state[OL_neuron] >= SPIKE_THRESHOLD) {
        return OL_neuron;
      }
    }
  }

  return -1;
}

void update_accuracy(int inference, int label, int *correct_guesses){
  if (inference == label) {
    (*correct_guesses)++;
  }
}

void print_accuracy(int *correct_guesses){
  float accuracy = (float)(*correct_guesses) / DATASET_SIZE * 100;
  printf("Accuracy: %.2f%%\n", accuracy);
}

int main() {
  int test_images[10000][256] = {0};
  int test_labels[DATASET_SIZE] = {0};
  int weights[IL_neurons][OL_neurons] = {0};

  int image[IMAGE_SIZE] = {0};
  int ROC_image[IMAGE_SIZE] = {0};

  char *file = NULL;
  int correct_guesses = 0;
    
  /* Parse pre-processed images*/
  file = "/mnt/c/Users/User/Documents/NTNU/Q4/GitHub/SnnAccelerator/data/test_images2.txt";
  read_2d_image_array_from_file(file, DATASET_SIZE, IMAGE_SIZE, test_images); 

  /* Parse test labels*/
  file = "/mnt/c/Users/User/Documents/NTNU/Q4/GitHub/SnnAccelerator/data/test_labels2.txt";
  read_array_from_file(file, DATASET_SIZE, test_labels); 

  /* Parse weights*/
  file = "/mnt/c/Users/User/Documents/NTNU/Q4/GitHub/SnnAccelerator/data/weights2.txt";
  read_2d_weight_array_from_file(file, IL_neurons, OL_neurons, weights); 

  /* Encode and then process each image with tinyODIN emulator*/
  for (int i = 0; i < DATASET_SIZE; i++){
    
    /* Select the image to process*/
    for (int j = 0; j < IMAGE_SIZE; j++) {
      image[j] = test_images[i][j];
    }

    /* Encode the image with ROC*/
    ROC_encode(image, ROC_image);

    /* Process the encoded image with tinyODIN and update metrics*/
    int inference = tinyODIN(ROC_image, weights);
    update_accuracy(inference, test_labels[i], &correct_guesses);

  }

  print_accuracy(&correct_guesses);

  return 0;
}
