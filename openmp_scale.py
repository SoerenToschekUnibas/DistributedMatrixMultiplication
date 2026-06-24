from matplotlib import pyplot as plt

#2 threads, running the scaled matrices.
thread_2 = [[2, 32, 2, 0.010355],
[2, 64, 2, 0.00775],
[2, 128, 2, 0.008612],
[2, 256, 2, 0.032063],
[2, 512, 2, 0.3652],
[2, 1024, 2, 3.56096],
[2, 2048, 2, 34.0882],
[2, 4096, 2, 321.943]]

thread_4 = [[4, 32, 4, 0.00767],
[4, 64, 4, 0.007676],
[4, 128, 4, 0.009581],
[4, 256, 4, 0.034545],
[4, 512, 4, 0.37612],
[4, 1024, 4, 3.77967],
[4, 2048, 4, 34.937],
[4, 4096, 4, 327.386]]

thread_128 = [
    [128, 32, 128, 0.007263],
    [   128, 64, 128, 0.007595],
    [    128, 128, 128, 0.010291],
    [    128, 256, 128, 0.032242],
    [    128, 512, 128, 0.353743],
    [    128, 1024, 128, 3.42309],
    [    128, 2048, 128, 33.0082]
]

plt.plot([entry[3] for entry in thread_2],label="2 Threads")
plt.plot([entry[3] for entry in thread_4],label="4 Threads")
plt.plot([entry[3] for entry in thread_128],label="128 Threads")
plt.yscale("log")
plt.xticks([i for i in range(8)],labels=[32,64,128,256,512,1024,2048,4096])
plt.xlabel("Matrix size")
plt.ylabel("Execution-time [s]")
plt.legend()
plt.show()

#matrix execution time, based on # threads.
matrix_2048 = []