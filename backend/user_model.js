const mongoose = require('mongoose')
const bcrypt = require('bcryptjs')
const jwt = require('jsonwebtoken')

const roles = ['UNVERIFIED', 'USER', 'SHELTER', 'SOCIETY', 'ADMIN']

const userSchema = new mongoose.Schema(
    {
        email: {
            type: String,
            //unique: true, todo -> FIX!!!!
            required: true,
            trim: true,
        },
        password: {
            type: String,
            trim: true,
            minlength: 7,
        },
        // Google unique id
        sub: {
            type: String,
        },
        // Facebook unique id
        fid: {
            type: String,
        },
        role: {
            type: String,
            default: roles[0],
        },
        tokens: [
            {
                token: {
                    type: String,
                    required: true,
                },
            },
        ],
        avatar: {
            type: Buffer,
        },
    },
    {
        timestamps: true,
    }
)

userSchema.pre('save', async function (next) {
    const user = this
    if(user.isModified('password')) {
        user.password = await bcrypt.hash(user.password, 8)
    }
    next()
})

userSchema.pre('remove', async function (next) {
    const user = this

    /*await Pets.deleteMany({
        owner: user._id
    });*/

    next()
})

userSchema.virtual('pets', {
    ref: 'Pet',
    localField: '_id',
    foreignField: 'owner',
})

userSchema.methods.toJSON = function () {
    const user = this

    const userObject = user.toObject()

    delete userObject.password
    delete userObject.tokens
    delete userObject.avatar

    return userObject
}

userSchema.statics.findAll = () => UserModel.find({})

userSchema.statics.findUserByEmail = email => UserModel.findOne({ email })

userSchema.statics.findUserBy = arg => UserModel.findOne(arg)

userSchema.statics.findUserById = id =>
    UserModel.findOne({ _id: mongoose.Types.ObjectId(id) })

userSchema.statics.getById = id => UserModel.findById(id)

userSchema.statics.findBy = query => UserModel.find(query)

userSchema.statics.isUserShelterRole = id => {
    const user = this.findUserById(id)
    return user
}

userSchema.statics.createNewUser = async body => {
    const newUser = new UserModel(body)
    await newUser.save()
    return newUser
}

userSchema.statics.delete = id => UserModel.findByIdAndDelete(id)

userSchema.methods.verifyPassword = function (password) {
    return bcrypt.compare(password, this.password)
}

userSchema.methods.isConfirmed = function () {
    return this.role !== roles[0]
}

userSchema.methods.generateAuthToken = async function () {
    const user = this
    const token = await jwt.sign(
        {
            _id: user._id.toString(),
        },
        process.env.JWT_SECRET
    )
    user.tokens = user.tokens.concat({ token })
    await user.save()
    return token
}

const UserModel = mongoose.model('User', userSchema)

module.exports = UserModel