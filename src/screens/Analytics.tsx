import React from 'react';
import { useStore } from '../store/useStore';
import { ArrowLeft, Star, TrendingUp, Clock } from 'lucide-react';

const mockPerformanceData = [
  { id: '01', name: 'KTC-01', trips: 142, peak: '8AM, 6PM', onTime: 87, delay: 3.2, status: 'Reliable', statusColor: 'var(--success)', rating: 4.8 },
  { id: '07', name: 'KTC-07', trips: 98, peak: '9AM, 5PM', onTime: 79, delay: 5.1, status: 'Usually on time', statusColor: 'var(--primary)', rating: 4.1 },
  { id: '12', name: 'KTC-12', trips: 76, peak: '7AM, 7PM', onTime: 72, delay: 6.5, status: 'Delays likely', statusColor: 'var(--warning)', rating: 3.2 },
];

const Analytics: React.FC = () => {
  const { setScreen } = useStore();

  return (
    <div style={{ height: '100%', width: '100%', background: 'var(--bg-color)', overflowY: 'auto', paddingBottom: '90px' }}>
      
      {/* Premium minimal header */}
      <div style={{ padding: '48px 24px 20px', background: 'var(--surface)', borderBottom: '1px solid var(--border-subtle)', position: 'sticky', top: 0, zIndex: 10 }}>
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center gap-4 cursor-pointer" onClick={() => setScreen('Home')}>
            <ArrowLeft size={24} className="text-primary" />
            <h1 className="text-2xl font-bold text-primary tracking-tight">Analytics</h1>
          </div>
        </div>
        <div className="text-sm text-muted">Network-wide insight and performance</div>
      </div>

      <div style={{ padding: '24px 20px' }}>
        
        {/* Metric Cards Grid */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '16px', marginBottom: '32px' }}>
          <div style={{ background: 'var(--surface)', borderRadius: 'var(--radius-xl)', padding: '20px', border: '1px solid var(--border)', boxShadow: 'var(--shadow-sm)' }}>
            <div style={{ width: '40px', height: '40px', borderRadius: '12px', background: 'var(--success-light)', color: 'var(--success)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '12px' }}>
              <TrendingUp size={20} />
            </div>
            <div className="font-bold text-2xl text-primary mb-1">79%</div>
            <div className="text-xs text-muted font-semibold tracking-wide uppercase">On-Time Avg</div>
          </div>
          
          <div style={{ background: 'var(--surface)', borderRadius: 'var(--radius-xl)', padding: '20px', border: '1px solid var(--border)', boxShadow: 'var(--shadow-sm)' }}>
             <div style={{ width: '40px', height: '40px', borderRadius: '12px', background: 'var(--warning-light)', color: 'var(--warning)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '12px' }}>
              <Clock size={20} />
            </div>
             <div className="font-bold text-2xl text-primary mb-1">5.0m</div>
            <div className="text-xs text-muted font-semibold tracking-wide uppercase">Avg Delay</div>
          </div>
        </div>

        <h2 className="font-bold text-lg mb-4 text-primary">Route Performance</h2>
        
        <div className="flex flex-col gap-4">
          {mockPerformanceData.map((data, i) => (
             <div key={i} style={{ background: 'var(--surface)', borderRadius: 'var(--radius-xl)', padding: '20px', border: '1px solid var(--border-subtle)', boxShadow: 'var(--shadow-sm)' }}>
               <div className="flex justify-between items-start mb-4">
                 <div className="flex items-center gap-4">
                   <div style={{ background: 'var(--bg-color)', border: '1px solid var(--border)', color: 'var(--primary)', fontWeight: 'bold', fontSize: '16px', width: '48px', height: '48px', borderRadius: '16px', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                     {data.id}
                   </div>
                   <div>
                     <div className="font-bold text-base text-primary mb-1">{data.name}</div>
                     <div className="text-xs text-muted font-medium">{data.trips} daily trips</div>
                   </div>
                 </div>
                 <div className="flex items-center gap-1 font-bold text-sm" style={{ color: data.statusColor }}>
                    <Star size={14} fill="currentColor" /> {data.rating}
                 </div>
               </div>
               
               <div className="flex justify-between items-center text-sm mb-2">
                 <span className="font-bold text-primary">{data.onTime}% On time</span>
                 <span className="text-xs font-semibold text-muted tracking-wide">{data.delay}m Avg delay</span>
               </div>
               
               {/* Clean Progress bar */}
               <div style={{ height: '8px', background: 'var(--bg-color)', borderRadius: 'var(--radius-full)', margin: '0 0 16px', overflow: 'hidden', border: '1px solid var(--border-subtle)' }}>
                 <div style={{ height: '100%', width: `${data.onTime}%`, background: data.statusColor, borderRadius: 'var(--radius-full)', transition: 'var(--transition)' }}></div>
               </div>
               
               <div className="flex justify-between items-center">
                 <div style={{ background: 'var(--bg-color)', padding: '6px 12px', borderRadius: 'var(--radius-full)', fontSize: '11px', fontWeight: 'bold', color: 'var(--primary)', border: '1px solid var(--border-subtle)' }}>
                   Peak: {data.peak}
                 </div>
                 <div style={{ color: data.statusColor, fontSize: '12px', fontWeight: 'bold' }}>
                   {data.status}
                 </div>
               </div>
             </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default Analytics;
