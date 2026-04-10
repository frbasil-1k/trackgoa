import React, { useState } from 'react';
import type { Bus, Route } from '../../data/mockData';
import { Users, AlertTriangle, ChevronRight } from 'lucide-react';
import { useStore } from '../../store/useStore';
import AlertModal from '../Alerts/AlertModal';

interface BusCardProps {
  bus: Bus;
  route: Route;
  etaMins: number;
  distanceKm: number;
  isBestOption?: boolean;
}

const BusCard: React.FC<BusCardProps> = ({ bus, route, etaMins, distanceKm, isBestOption }) => {
  const { touristMode, setTrackedBus } = useStore();
  const [showAlertModal, setShowAlertModal] = useState(false);

  const getCrowdColor = (level: string) => {
    switch (level) {
      case 'Low': return 'var(--success)';
      case 'Medium': return 'var(--warning)';
      case 'High': return 'var(--danger)';
      default: return 'var(--text-muted)';
    }
  };

  const getCrowdBg = (level: string) => {
    switch (level) {
      case 'Low': return 'var(--success-light)';
      case 'Medium': return 'var(--warning-light)';
      case 'High': return 'var(--danger-light)';
      default: return 'var(--bg-color)';
    }
  };

  const catchStatusColor = etaMins > 0.5 ? 'var(--success)' : 'var(--danger)';

  return (
    <>
      <div style={{
        background: 'var(--surface)',
        borderRadius: 'var(--radius-xl)',
        padding: '20px',
        marginBottom: '4px',
        border: '1px solid var(--border-subtle)',
        boxShadow: 'var(--shadow-sm)',
        position: 'relative',
        overflow: 'hidden'
      }}>
        {/* Top row */}
        <div className="flex justify-between items-start" style={{ marginBottom: '16px' }}>
          <div className="flex items-center gap-4">
            <div style={{
              background: 'var(--bg-color)', color: 'var(--primary)',
              width: '48px', height: '48px', display: 'flex', alignItems: 'center', justifyContent: 'center',
              borderRadius: '16px', fontWeight: 'bold', fontSize: '18px', border: '1px solid var(--border)'
            }}>
              {bus.id.replace('b', '0')}
            </div>
            <div>
              <div className="font-bold text-base text-primary mb-1">{route.name}</div>
              <div className="flex gap-2">
                {bus.status === 'Stopped' && (
                  <span style={{ fontSize: '10px', background: 'var(--warning-light)', color: 'var(--warning)', padding: '2px 6px', borderRadius: 'var(--radius-full)', fontWeight: 'bold' }}>STOPPED</span>
                )}
                {bus.delay > 3 && (
                  <span className="flex items-center gap-1 text-[10px]" style={{ color: 'var(--danger)', fontWeight: 'bold', background: 'var(--danger-light)', padding: '2px 8px', borderRadius: 'var(--radius-full)' }}>
                    Delayed
                  </span>
                )}
                {isBestOption && (
                   <span style={{ fontSize: '10px', background: 'rgba(37,99,235,0.1)', color: 'var(--accent)', padding: '2px 8px', borderRadius: 'var(--radius-full)', fontWeight: 'bold' }}>
                    Top Pick
                  </span>
                )}
              </div>
            </div>
          </div>
          
          <div className="flex flex-col items-end">
            <div className="flex items-center gap-1 font-bold text-xl" style={{ color: 'var(--primary)' }}>
              {Number.isNaN(etaMins) ? '--' : Math.max(1, Math.round(etaMins))} <span className="text-sm text-muted mb-1">min</span>
            </div>
            <div className="text-xs font-semibold" style={{ color: catchStatusColor }}>
              {Math.max(0.1, distanceKm).toFixed(1)} km away
            </div>
          </div>
        </div>

        {/* Action row container matching base44 smooth aesthetic */}
        <div className="flex justify-between items-center bg-transparent mt-4" style={{ borderTop: '1px solid var(--border-subtle)', paddingTop: '16px' }}>
          
           {/* Crowd indicator as pill */}
          <div className="flex items-center gap-1 text-xs font-bold" style={{ color: getCrowdColor(bus.crowdLevel), background: getCrowdBg(bus.crowdLevel), padding: '6px 12px', borderRadius: 'var(--radius-full)' }}>
            <Users size={14} /> {bus.crowdLevel}
          </div>

          <div className="flex gap-2">
            <button onClick={() => setShowAlertModal(true)} style={{
              width: '36px', height: '36px', borderRadius: '50%',
              background: 'var(--bg-color)', border: '1px solid var(--border)',
              color: 'var(--text-main)', cursor: 'pointer', display: 'flex', justifyContent: 'center', alignItems: 'center', transition: 'var(--transition)'
            }} className="active:scale-95">
              <AlertTriangle size={16} className="text-muted" />
            </button>
            <button onClick={() => setTrackedBus(bus.id)} style={{
              padding: '0 20px', height: '36px', borderRadius: '18px',
              background: 'var(--primary)', border: 'none',
              color: 'white', fontSize: '13px', fontWeight: 'bold', cursor: 'pointer',
              display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '6px', boxShadow: 'var(--shadow-sm)', transition: 'var(--transition)'
            }} className="active:scale-95">
              Track <ChevronRight size={14} />
            </button>
          </div>
        </div>

        {touristMode && (
          <div style={{ marginTop: '12px', padding: '12px', background: 'var(--bg-color)', borderRadius: '12px', borderLeft: '3px solid var(--accent)' }}>
            <p className="text-xs" style={{ color: 'var(--primary)', fontWeight: 500 }}><span className="font-bold text-accent">Tourist Tip:</span> {route.stops[Math.floor(route.stops.length/2)].touristName} is on this route.</p>
          </div>
        )}
      </div>

      {showAlertModal && <AlertModal busId={bus.id} onClose={() => setShowAlertModal(false)} />}
    </>
  );
};

export default BusCard;
