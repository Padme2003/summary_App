const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'El nombre es requerido'],
    trim: true,
  },
  email: {
    type: String,
    required: [true, 'El email es requerido'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Email inválido'],
  },
  password: {
    type: String,
    required: [true, 'La contraseña es requerida'],
    minlength: [6, 'La contraseña debe tener al menos 6 caracteres'],
    select: false,
  },
  avatar: {
    type: String,
    default: null,
  },
  role: {
    type: String,
    enum: ['user', 'premium', 'admin'],
    default: 'user',
  },
  subscription: {
    type: {
      type: String,
      enum: ['free', 'premium'],
      default: 'free',
    },
    expiresAt: Date,
  },
  preferences: {
    theme: {
      type: String,
      enum: ['light', 'dark', 'auto'],
      default: 'auto',
    },
    language: {
      type: String,
      default: 'es',
    },
    notifications: {
      type: Boolean,
      default: true,
    },
  },
  stats: {
    totalDocuments: {
      type: Number,
      default: 0,
    },
    totalSummaries: {
      type: Number,
      default: 0,
    },
    totalAudiobooks: {
      type: Number,
      default: 0,
    },
  },
  audiobookQuota: {
    used: {
      type: Number,
      default: 0,
    },
    limit: {
      type: Number,
      default: 10, // 10 para usuarios gratuitos, -1 para premium (ilimitado)
    },
    resetDate: {
      type: Date,
      default: () => {
        const date = new Date();
        date.setMonth(date.getMonth() + 1);
        date.setDate(1);
        date.setHours(0, 0, 0, 0);
        return date;
      },
    },
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  lastLogin: {
    type: Date,
  },
  resetPasswordCode: {
    type: String,
    select: false,
  },
  resetPasswordExpires: {
    type: Date,
    select: false,
  },
}, {
  timestamps: true,
});

// Hash password antes de guardar
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();

  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Método para comparar contraseñas
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Método para verificar y resetear cuota de audiolibros
userSchema.methods.checkAndResetAudiobookQuota = function() {
  const now = new Date();
  if (now >= this.audiobookQuota.resetDate) {
    // Reset mensual
    this.audiobookQuota.used = 0;
    const nextReset = new Date(now);
    nextReset.setMonth(nextReset.getMonth() + 1);
    nextReset.setDate(1);
    nextReset.setHours(0, 0, 0, 0);
    this.audiobookQuota.resetDate = nextReset;
  }
};

// Método para verificar si tiene cuota disponible
userSchema.methods.hasAudiobookQuota = function() {
  this.checkAndResetAudiobookQuota();

  // Premium tiene ilimitado
  if (this.subscription.type === 'premium' || this.audiobookQuota.limit === -1) {
    return true;
  }

  // Verificar si aún tiene cuota disponible
  return this.audiobookQuota.used < this.audiobookQuota.limit;
};

// Método para obtener datos públicos del usuario
userSchema.methods.toJSON = function() {
  const user = this.toObject();
  delete user.password;
  return user;
};

module.exports = mongoose.model('User', userSchema);
