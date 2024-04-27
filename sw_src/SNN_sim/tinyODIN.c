#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>
#include <inttypes.h>
#include <stdbool.h>

// MNIST images have been resized to 16x16
#define IMAGE_SIZE 10

// Each pixel on MNIST is a value from 0 to 255, stored as integers
#define PIXEL_MAX_VALUE 12

// Number of digits in the base 10 number system
#define BASE_10 10


void print_array(int array[]){
  printf("[");
  for (int i = 0; i < IMAGE_SIZE; i++) {
    printf("%d", array[i]);
    if (i < IMAGE_SIZE - 1) {
      printf(", \t"); 
    }
  }
  printf("]\n\n");
}

void ROC_counting_sort(int input_array[], int sorted_array[]) {
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

  // Fill sorted array using counting sort
  for (int pixelID = IMAGE_SIZE - 1; pixelID >= 0; pixelID--) {
    int intensity = input_array[pixelID];
    // Store the value to the sorted array
    sorted_array[frequency[intensity] - 1] = pixelID;
    frequency[intensity]--;
  }

  // print_array(sorted_array);
}


int main() {
  int image[IMAGE_SIZE];
  int sorted_indexes[IMAGE_SIZE];

  /* Parse pre-processed image*/


  /* Encode the image with ROC*/
  ROC_counting_sort(image, sorted_indexes);

  /* Process spikes with tinyODIN */

  return 0;
}
