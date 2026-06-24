from matplotlib import pyplot as plt


"""
104644
57145
41818
37929
28001
25768
"""

data = [104644, 57145, 41818, 37929, 28001, 25768]
num_blocks = [1, 2, 4, 8, 16, 32]

#Plot, using a log-log scale.
plt.figure(figsize=(10, 6))
plt.plot(data, marker='o', label='Measured Time', color='blue')
plt.xticks([i for i in range(6)],labels=num_blocks)
plt.yscale("log")
plt.xlabel("Number of Blocks")
plt.ylabel("Compute Time")
plt.title("Constant problem size")
#plt.legend()
plt.grid(True)
plt.show()

runtime_weak_scaling = [
    15001,
    21977,
    25644,
    21711,
    20578
    ]

matrix_sizes = [512,1024,1536,2048,3072]
plt.figure(figsize=(10, 6))
plt.title("Proportional problem size")
plt.plot(matrix_sizes,runtime_weak_scaling, marker='o')
plt.xticks([512,1024,2048],labels=["512;\n1 Block","1024;\n8 Block","2048;\n64 Block"])
plt.ylabel("Compute Time")
plt.show()