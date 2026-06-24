from matplotlib import pyplot as plt


data = []


list_of_thread_counts = [i for i in range(1,17)]

num_runs = 32

for run_index in range(num_runs):
    data.append([])
    for num_threads in list_of_thread_counts:
        with open("transposition_execution_time/run_" + str(run_index)+"/transposition_"+str(num_threads)+".txt") as f:
            data[run_index].append([])
            for line in f.readlines():
                entries = line.split(",")
                data[run_index][-1].append(float(entries[1]))
        



mean_pts = []
for i in range(len(data[0])):
    #number of threads.
    s = 0.0
    for run_index in range(num_runs):
        s += data[run_index][i][3]
    mean_pts.append(s/num_runs)


for run_index in range(num_runs):
    plt.plot([data[run_index][i][3] for i in range(len(data[run_index]))],label="",color="gray",linewidth=1)
plt.plot(mean_pts,label="",color="blue",linewidth=5)

plt.xticks([i for i in range(len(list_of_thread_counts))],labels=list_of_thread_counts,)
plt.xlabel("# Threads")
plt.ylabel("runtime")
plt.show()



for i in range(5):
    plt.plot(data[0][i], label=str(2**i) + " Threads")
plt.title("Matrix Transposition")
plt.xlabel("Matrix size")
plt.ylabel("Execution Time")
plt.legend()
#plt.xticks([i for i in range(len(data[0]))],labels=[64,128,256,512,1024,2048,4096,8192])
plt.show()
    