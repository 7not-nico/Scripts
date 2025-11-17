import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv('data.csv')

def parse_time(t):
    if 'm' in t:
        m, s = t.split('m')
        return int(m) * 60 + float(s)
    else:
        return float(t)

df['time_sec'] = df['time'].apply(parse_time)

avg = df.groupby('script')['time_sec'].mean()

avg.plot(kind='bar', figsize=(10,6))
plt.title('Average Execution Time for Scripts (3 runs)')
plt.ylabel('Time (seconds)')
plt.xlabel('Script')
plt.xticks(rotation=45)
plt.tight_layout()
plt.savefig('timings_graph.png')

print('Graph saved to timings_graph.png')