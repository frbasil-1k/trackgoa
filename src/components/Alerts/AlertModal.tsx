import React from 'react';
import { useStore } from '../../store/useStore';
import type { Alert } from '../../store/useStore';
import { motion } from 'framer-motion';
import { Bell, Clock, MapPin, X, ChevronRight } from 'lucide-react';

interface Props {
  busId: string;
  onClose: () => void;
}

const AlertModal: React.FC<Props> = ({ busId, onClose }) => {
  const addAlert = useStore(state => state.addAlert);

  const handleCreateAlert = (type: Alert['type'], value: number) => {
    addAlert({ busId, type, value, message: `Bus ${busId.toUpperCase()} is arriving soon!` });
    
    // Dispatch a custom event to show a toast in App.tsx
    window.dispatchEvent(new CustomEvent('app-toast', { detail: { message: `Alert set for Bus ${busId.replace('b', '0')}!`, type: 'success' } }));
    onClose();
  };

  return (
    <div style={{
      position: 'absolute',
      top: 0, left: 0, right: 0, bottom: 0,
      backgroundColor: 'rgba(0,0,0,0.4)',
      backdropFilter: 'blur(4px)',
      zIndex: 2000,
      display: 'flex',
      alignItems: 'flex-end',
      justifyContent: 'center',
    }}>
      <motion.div 
        initial={{ y: '100%', opacity: 0.5 }} animate={{ y: 0, opacity: 1 }} exit={{ y: '100%' }}
        transition={{ type: 'spring', damping: 25, stiffness: 300 }}
        style={{
          width: '100%',
          maxWidth: '480px',
          background: 'var(--surface)',
          borderTopLeftRadius: 'var(--radius-2xl)',
          borderTopRightRadius: 'var(--radius-2xl)',
          padding: '24px 20px 40px',
          boxShadow: '0 -10px 40px rgba(0,0,0,0.1)'
        }}
        onClick={(e) => e.stopPropagation()} // Prevent closing when clicking inside
      >
        <div className="flex justify-between items-center mb-6">
          <div>
            <h2 className="text-xl font-bold text-primary">Smart Alerts</h2>
            <p className="text-xs text-muted mt-1">Get notified before your bus arrives</p>
          </div>
          <button onClick={onClose} style={{ background: 'var(--bg-color)', border: 'none', width: '36px', height: '36px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}><X size={20} className="text-muted" /></button>
        </div>

        <div className="flex flex-col gap-3">
          <button onClick={() => handleCreateAlert('Time', 2)} className="alert-btn">
            <div className="flex items-center gap-3">
              <div style={{ background: 'rgba(37,99,235,0.1)', color: 'var(--accent)', padding: '10px', borderRadius: '12px' }}><Clock size={20} /></div>
              <div className="text-left">
                <div className="font-bold text-sm text-primary">Time Alert</div>
                <div className="text-xs text-muted">Notify me 2 mins away</div>
              </div>
            </div>
            <ChevronRight size={18} className="text-muted" />
          </button>
          
          <button onClick={() => handleCreateAlert('Stops', 1)} className="alert-btn">
            <div className="flex items-center gap-3">
              <div style={{ background: 'var(--warning-light)', color: 'var(--warning)', padding: '10px', borderRadius: '12px' }}><Bell size={20} /></div>
              <div className="text-left">
                <div className="font-bold text-sm text-primary">Stop Alert</div>
                <div className="text-xs text-muted">Notify me 1 stop away</div>
              </div>
            </div>
            <ChevronRight size={18} className="text-muted" />
          </button>

          <button onClick={() => handleCreateAlert('Distance', 500)} className="alert-btn">
            <div className="flex items-center gap-3">
              <div style={{ background: 'var(--success-light)', color: 'var(--success)', padding: '10px', borderRadius: '12px' }}><MapPin size={20} /></div>
              <div className="text-left">
                <div className="font-bold text-sm text-primary">Distance Alert</div>
                <div className="text-xs text-muted">Notify me 500m away</div>
              </div>
            </div>
            <ChevronRight size={18} className="text-muted" />
          </button>
        </div>
      </motion.div>

      <style>{`
        .alert-btn {
          display: flex; align-items: center; justify-content: space-between;
          padding: 12px; border-radius: var(--radius-xl);
          background: var(--surface); border: 1px solid var(--border);
          width: 100%; cursor: pointer; transition: var(--transition);
        }
        .alert-btn:active {
          transform: scale(0.98); background: var(--bg-color);
        }
      `}</style>
    </div>
  );
};

export default AlertModal;
