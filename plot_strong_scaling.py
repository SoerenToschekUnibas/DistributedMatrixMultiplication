from matplotlib import pyplot as plt


"""
compute time: 104644
compute time: 57145
compute time: 41818
compute time: 37929
compute time: 28001
compute time: 25768
"""

data = [104644, 57145, 41818, 37929, 28001, 25768]
num_blocks = [1, 2, 4, 8, 16, 32]

#Plot, using a log-log scale.
plt.figure(figsize=(10, 6))
plt.plot(num_blocks, data, marker='o', label='Measured Time', color='blue')
plt.xscale("log")
plt.yscale("log")
plt.xlabel("Number of Blocks")
plt.ylabel("Compute Time")
plt.title("Constant problem size")
#plt.legend()
plt.grid(True)
plt.show()