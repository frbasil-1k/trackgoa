import React from 'react';
import { useStore } from '../../store/useStore';
import type { Alert } from '../../store/useStore';
import { motion } from 'framer-motion';
import { Bell, Clock, MapPin, X } from 'lucide-react';

interface Props {
  busId: string;
  onClose: () => void;
}

const AlertModal: React.FC<Props> = ({ busId, onClose }) => {
  const addAlert = useStore(state => state.addAlert);

  const handleCreateAlert = (type: Alert['type'], value: number) => {
    addAlert({ busId, type, value, message: `Bus ${busId.toUpperCase()} is arriving soon!` });
    
    // Dispatch a dummy toast to confirm saving
    window.dispatchEvent(new CustomEvent('smart-alert', { detail: 'Alert saved successfully.' }));
    onClose();
  };

  return (
    <div style={{
      position: 'absolute',
      top: 0, left: 0, right: 0, bottom: 0,
      backgroundColor: 'rgba(0,0,0,0.5)',
      zIndex: 2000,
      display: 'flex',
      alignItems: 'flex-end'
    }}>
      <motion.div 
        initial={{ y: '100%' }} animate={{ y: 0 }} exit={{ y: '100%' }}
        style={{
          width: '100%',
          background: 'var(--surface)',
          borderTopLeftRadius: 'var(--radius-lg)',
          borderTopRightRadius: 'var(--radius-lg)',
          padding: '24px'
        }}
      >
        <div className="flex justify-between items-center mb-6" style={{ marginBottom: '24px' }}>
          <h2 className="text-lg font-bold">Smart Alerts</h2>
          <button onClick={onClose} style={{ background: 'transparent', border: 'none' }}><X size={24} /></button>
        </div>

        <div className="flex flex-col gap-3">
          <button onClick={() => handleCreateAlert('Time', 2)} className="alert-btn">
            <Clock size={20} /> Notify me 2 minutes away
          </button>
          <button onClick={() => handleCreateAlert('Stops', 1)} className="alert-btn">
            <Bell size={20} /> Notify me 1 stop away
          </button>
          <button onClick={() => handleCreateAlert('Distance', 500)} className="alert-btn">
            <MapPin size={20} /> Notify me when 500 meters away
          </button>
        </div>
      </motion.div>

      <style>{`
        .alert-btn {
          display: flex; align-items: center; gap: 12px;
          padding: 16px; border-radius: var(--radius);
          background: var(--bg-color); border: 1px solid var(--border);
          width: 100%; font-size: 15px; font-weight: 600;
          color: var(--text-main); cursor: pointer;
        }
      `}</style>
    </div>
  );
};

export default AlertModal;
