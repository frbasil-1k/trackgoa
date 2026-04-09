import React from 'react';
import { useStore } from '../../store/useStore';
import { Menu, Search, Map, ChevronLeft } from 'lucide-react';

const FloatingControls: React.FC = () => {
  const { toggleTouristMode, touristMode, trackedBusId, setTrackedBus } = useStore();

  return (
    <>
      <div style={{ position: 'absolute', top: '16px', left: '16px', right: '16px', zIndex: 400, display: 'flex', gap: '12px' }}>
        {trackedBusId ? (
          <button className="floating-btn" onClick={() => setTrackedBus(null)} style={{ position: 'relative', width: '48px' }}>
            <ChevronLeft size={24} />
          </button>
        ) : (
          <button className="floating-btn" style={{ position: 'relative' }}>
            <Menu size={20} />
          </button>
        )}
        
        <div className="glass" style={{ 
          flex: 1, display: 'flex', alignItems: 'center', padding: '0 16px', 
          borderRadius: 'var(--radius-full)', boxShadow: 'var(--shadow)'
        }}>
          {trackedBusId ? (
            <span className="font-semibold" style={{ margin: 'auto' }}>Tracking Bus {trackedBusId.toUpperCase()}</span>
          ) : (
            <>
              <Search size={18} className="text-muted" style={{ marginRight: '8px' }} />
              <input type="text" placeholder="Search stops, routes..." style={{ border: 'none', background: 'transparent', outline: 'none', width: '100%', fontSize: '15px' }} readOnly />
            </>
          )}
        </div>
      </div>

      <div style={{ position: 'absolute', top: '80px', right: '16px', zIndex: 400, display: 'flex', flexDirection: 'column', gap: '12px' }}>
        <button 
          className="floating-btn" 
          onClick={toggleTouristMode}
          style={{ position: 'relative', background: touristMode ? 'var(--warning)' : 'var(--surface)', color: touristMode ? 'white' : 'var(--text-main)' }}
        >
          <Map size={20} />
        </button>
      </div>
    </>
  );
};

export default FloatingControls;
