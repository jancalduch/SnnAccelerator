import pickle

class Syn:
    def __init__(self, weight):
        self.weight = weight

with open('./weights_85p1.pkl', 'rb') as f:
    synarray = pickle.load(f)


# ------------------------------------------------------------------ Weights of each output neuron
# for i in range(10):
#     print("ON "+str(i)+": ")
#     for j in range(len(synarray)):
#         print(synarray[j][i].weight, end=',')
#     print("\n")
    

# ------------------------------------------------------------------ Weights of each input neuron
matrix = [[0 for j in range(10)] for i in range(len(synarray))]
for i in range(len(synarray)):
    for j in range(10):
        matrix[i][j] = synarray[i][j].weight

# Show all results except the ones where input neuron has no connections
for i in range(len(synarray)):
    sum = 0
    for j in range(10):
        sum += matrix[i][j]
    if (sum != 0):    
        print("Input neuron "+str(i)+": ", end='')
        print(matrix[i])

# ------------------------------------------------------------------ Generate SV array
# matrix = [[0 for j in range(10)] for i in range(len(synarray))]
# for i in range(len(synarray)):
#     for j in range(10):
#         matrix[i][j] = synarray[i][j].weight

# for i in range(len(synarray)):
#     print("weights["+str(i)+"] \t = {", end='')
#     for j in range(10): 
#         print(str(matrix[i][j]), end=',')
#     print('};')  

# ------------------------------------------------------------------ Generate python array
# matrix = [[0 for j in range(10)] for i in range(len(synarray))]
# for i in range(len(synarray)):
#     for j in range(10):
#         matrix[i][j] = synarray[i][j].weight

# for i in range(len(synarray)):
#     print("weights["+str(i)+"] \t = [", end='')
#     for j in range(10-1): 
#         print(str(matrix[i][j]), end=',')
#     print(str(matrix[i][9]), end='')
#     print(']')   
    
# ------------------------------------------------------------------ Frenkel code
# for i in range(10):
#     for j in range(len(synarray)):
#         print("Weight from neuron "+str(j)+" to output neuron "+str(i)+" is "+str(synarray[j][i].weight))