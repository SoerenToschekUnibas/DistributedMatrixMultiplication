import matplotlib.pyplot as plt

dynamic_pts = [
    [32, 2, 0.006957],
    [64, 2, 0.004338],
    [128, 2, 0.005585],
    [256, 2, 0.027935],
    [512, 2, 0.350184],
    [1024, 2, 3.38904],
    [2048, 2, 32.0888],
    [32, 4, 0.004553],
    [64, 4, 0.005286],
    [128, 4, 0.006412],
    [256, 4, 0.028484],
    [512, 4, 0.339864],
    [1024, 4, 3.31931],
    [2048, 4, 30.7548],
    [32, 8, 0.004743],
    [64, 8, 0.004843],
    [128, 8, 0.006402],
    [256, 8, 0.02899],
    [512, 8, 0.335999],
    [1024, 8, 3.38085],
    [2048, 8, 31.2468]
]
static_pts = [
    [32, 2, 0.003843],
    [64, 2, 0.00408],
    [128, 2, 0.005674],
    [256, 2, 0.028868],
    [512, 2, 0.356784],
    [1024, 2, 3.42825],
    [2048, 2, 31.1778],
    [32, 4, 0.004617],
    [64, 4, 0.004601],
    [128, 4, 0.006433],
    [256, 4, 0.028726],
    [512, 4, 0.336616],
    [1024, 4, 3.2771],
    [2048, 4, 31.3556],
    [32, 8, 0.004678],
    [64, 8, 0.004835],
    [128, 8, 0.006493],
    [256, 8, 0.029125],
    [512, 8, 0.340639],
    [1024, 8, 3.31394],
]



guided_pts = [
    [32, 2, 0.004116],
    [64, 2, 0.004474],
    [128, 2, 0.005656],
    [256, 2, 0.02848],
    [512, 2, 0.356159],
    [1024, 2, 3.34664],
    [2048, 2, 31.0105],
    [32, 4, 0.004682],
    [64, 4, 0.004681],
    [128, 4, 0.006445],
    [256, 4, 0.028475],
    [512, 4, 0.334735],
    [1024, 4, 3.31394],
    [2048, 4, 31.3235],
    [32, 8, 0.004639],
    [64, 8, 0.004881],
    [128, 8, 0.006577],
    [256, 8, 0.029243],
    [512, 8, 0.338228],
    [1024, 8, 3.57372],
    [2048, 8, 31.7328],
]


dynamic_data = [[0 for size in [32,64,128,256,512,1024]] for thread in [2,4,8]]
static_data = [[0 for size in [32,64,128,256,512,1024]] for thread in [2,4,8]]
guided_data = [[0 for size in [32,64,128,256,512,1024]] for thread in [2,4,8]]
for threads in range(3):
    for size in range(6):
        dynamic_data[threads][size] =  dynamic_pts[threads*7+size]
        static_data[threads][size] =  static_pts[threads*7+size]
        guided_data[threads][size] =  guided_pts[threads*7+size]

size_range = [2**i for i in range(5,11)]


plt.plot(size_range, dynamic_data[1],label="dynamic")
plt.plot(size_range,static_data[1],label="static")
plt.plot(size_range,guided_data[1],label="guided")
plt.xticks([i for i in range(6)],labels=[32,64,128,256,512,1024])

plt.yscale("log")
plt.xlabel("Matrix size")
plt.ylabel("Execution time")
plt.show()


plt.plot([dynamic_data[i][2] for i in range(3)],label="dynamic")
plt.plot([static_data[i][2] for i in range(3)],label="static")
plt.plot([guided_data[i][2] for i in range(3)],label="guided")

plt.yscale("log")
plt.xticks([i for i in range(3)],labels=[2,4,8])
plt.xlabel("# Thread")
plt.ylabel("Execution time")
plt.show()