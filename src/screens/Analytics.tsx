import React from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

const mockPerformanceData = [
  { name: 'Panaji-Miramar', onTime: 92, delay: 8 },
  { name: 'Margao-Fatorda', onTime: 78, delay: 22 },
  { name: 'Vasco-Chicalim', onTime: 85, delay: 15 },
];

const Analytics: React.FC = () => {
  return (
    <div style={{ height: '100%', width: '100%', background: 'var(--bg-color)', overflowY: 'auto', paddingBottom: '80px' }}>
      
      <div style={{ padding: '24px 20px', background: 'var(--primary)', color: 'white' }}>
        <h1 className="text-lg font-bold">Transit Analytics</h1>
        <p className="text-sm" style={{ opacity: 0.8 }}>Live route performance monitoring</p>
      </div>

      <div style={{ padding: '20px' }}>
        <h2 className="font-semibold mb-4" style={{ marginBottom: '16px' }}>Network Overview</h2>
        
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '24px' }}>
          <div className="glass" style={{ padding: '16px', borderRadius: 'var(--radius)', textAlign: 'center' }}>
            <div className="text-2xl font-bold" style={{ color: 'var(--success)' }}>87%</div>
            <div className="text-xs text-muted">Network On-Time</div>
          </div>
          <div className="glass" style={{ padding: '16px', borderRadius: 'var(--radius)', textAlign: 'center' }}>
            <div className="text-2xl font-bold" style={{ color: 'var(--danger)' }}>12m</div>
            <div className="text-xs text-muted">Avg Delay</div>
          </div>
        </div>

        <h2 className="font-semibold mb-4" style={{ marginBottom: '16px' }}>Route Reliability</h2>
        
        <div className="glass" style={{ borderRadius: 'var(--radius)', padding: '16px', height: '250px' }}>
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={mockPerformanceData}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--border)" />
              <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 10 }} />
              <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 10 }} />
              <Tooltip cursor={{ fill: 'rgba(0,0,0,0.05)' }} />
              <Bar dataKey="onTime" name="On Time %" stackId="a" fill="var(--success)" radius={[0, 0, 4, 4]} />
              <Bar dataKey="delay" name="Delay %" stackId="a" fill="var(--danger)" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};

export default Analytics;
