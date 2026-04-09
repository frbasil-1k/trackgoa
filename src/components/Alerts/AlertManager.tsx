import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const AlertManager: React.FC = () => {
  const [toasts, setToasts] = useState<{id: string, text: string}[]>([]);

  useEffect(() => {
    const handleAlert = (e: any) => {
      const newToast = { id: Date.now().toString(), text: e.detail };
      setToasts(prev => [...prev, newToast]);
      
      // Auto remove after 4 secs
      setTimeout(() => {
        setToasts(prev => prev.filter(t => t.id !== newToast.id));
      }, 4000);
    };

    window.addEventListener('smart-alert', handleAlert);
    return () => window.removeEventListener('smart-alert', handleAlert);
  }, []);

  return (
    <div style={{
      position: 'absolute',
      top: '80px',
      left: '50%',
      transform: 'translateX(-50%)',
      width: '90%',
      maxWidth: '400px',
      zIndex: 1000,
      display: 'flex',
      flexDirection: 'column',
      gap: '8px'
    }}>
      <AnimatePresence>
        {toasts.map(toast => (
          <motion.div
            key={toast.id}
            initial={{ opacity: 0, y: -20, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            style={{
              background: 'var(--surface)',
              borderLeft: '4px solid var(--primary)',
              padding: '12px 16px',
              borderRadius: 'var(--radius)',
              boxShadow: 'var(--shadow-lg)',
              display: 'flex',
              alignItems: 'center',
              fontWeight: 600,
              fontSize: '14px'
            }}
          >
            🔔 {toast.text}
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
};

export default AlertManager;
