import React, { useState } from 'react';
import type { Bus, Route } from '../../data/mockData';
import { MapPin, Navigation, Users, Clock, AlertTriangle, Smartphone } from 'lucide-react';
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

  // Catchability Check logic
  const catchStatus = etaMins > 0.5 ? 'Can Catch' : 'Too Close';
  const catchStatusColor = etaMins > 0.5 ? 'var(--success)' : 'var(--danger)';

  return (
    <>
      <div style={{
        background: 'var(--surface)',
        borderRadius: 'var(--radius-lg)',
        padding: '16px',
        marginBottom: '12px',
        border: isBestOption ? '2px solid var(--primary)' : '1px solid var(--border)',
        boxShadow: isBestOption ? '0 4px 12px rgba(37,99,235,0.2)' : 'var(--shadow-sm)',
        position: 'relative',
        overflow: 'hidden'
      }}>
        {isBestOption && (
          <div style={{ position: 'absolute', top: 0, right: 0, background: 'var(--primary)', color: 'white', fontSize: '10px', padding: '4px 8px', borderBottomLeftRadius: 'var(--radius-md)', fontWeight: 'bold' }}>
            ✨ Best Option
          </div>
        )}

        {/* Top row */}
        <div className="flex justify-between items-center" style={{ marginBottom: '12px' }}>
          <div className="flex items-center gap-2">
            <div style={{
              background: 'var(--primary)', color: 'white', padding: '4px 8px',
              borderRadius: 'var(--radius-md)', fontWeight: 'bold', fontSize: '14px'
            }}>
              {bus.id.toUpperCase()}
            </div>
            <span className="font-semibold text-sm">{route.name}</span>
          </div>
          
          <div className="flex gap-2">
            {bus.status === 'Stopped' && (
              <span style={{ fontSize: '11px', background: 'var(--warning)', color: 'white', padding: '2px 6px', borderRadius: '4px', fontWeight: 'bold' }}>STOPPED</span>
            )}
            {bus.delay > 3 && (
              <div className="flex items-center gap-1 text-xs font-semibold" style={{ color: 'var(--danger)' }}>
                <AlertTriangle size={14} /> Delayed
              </div>
            )}
          </div>
        </div>

        {/* Main Info */}
        <div className="flex justify-between items-center" style={{ marginBottom: '16px' }}>
          <div>
            <div className="flex items-center gap-2 font-bold text-lg" style={{ color: 'var(--primary)' }}>
              <Clock size={20} />
              {Math.max(1, Math.round(etaMins))} mins
            </div>
            <div className="text-sm text-muted" style={{ marginTop: '4px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <span>{Math.max(0.1, distanceKm).toFixed(1)} km</span> • 
              <span style={{ color: catchStatusColor, fontWeight: 600, display: 'flex', alignItems:'center', gap:'2px' }}>
                <Smartphone size={14}/> {catchStatus}
              </span>
            </div>
          </div>
          
          <div className="flex flex-col items-end">
            <span className="text-xs text-muted mb-1">Crowd</span>
            <div className="flex items-center gap-1 text-sm font-semibold" style={{ color: getCrowdColor(bus.crowdLevel) }}>
              <Users size={16} /> {bus.crowdLevel}
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="flex gap-2">
          <button onClick={() => setTrackedBus(bus.id)} style={{
            flex: 1, padding: '10px', borderRadius: 'var(--radius-md)',
            background: 'var(--bg-color)', border: '1px solid var(--border)',
            color: 'var(--text-main)', fontSize: '14px', fontWeight: 600,
            cursor: 'pointer', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '6px'
          }}>
            <MapPin size={16} /> Track
          </button>
          <button onClick={() => setShowAlertModal(true)} style={{
            flex: 1, padding: '10px', borderRadius: 'var(--radius-md)',
            background: 'var(--primary)', border: 'none',
            color: 'white', fontSize: '14px', fontWeight: 600, cursor: 'pointer',
            display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '6px'
          }}>
            <Navigation size={16} /> Set Alert
          </button>
        </div>

        {touristMode && (
          <div style={{ marginTop: '12px', padding: '8px', background: 'rgba(245, 158, 11, 0.1)', borderRadius: 'var(--radius)', borderLeft: '3px solid var(--warning)' }}>
            <p className="text-xs" style={{ color: 'var(--warning)', fontWeight: 600 }}>💡 Tourist Tip: {route.stops[route.stops.length-1].touristName} is on this route!</p>
          </div>
        )}
      </div>

      {showAlertModal && <AlertModal busId={bus.id} onClose={() => setShowAlertModal(false)} />}
    </>
  );
};

export default BusCard;
