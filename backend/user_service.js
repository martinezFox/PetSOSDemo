const { ErrorHandler } = require('../helpers/error')

const UserService = ({ userModel, google, facebook, sendGrid, sosModel }) => {
    const login = async (params) => {
        const user = await userModel.findUserBy({ email: params.email })
        if(!user) throw new ErrorHandler(403, 'Uporabnik ne obstaja.')

        if(user.sub) throw new ErrorHandler(404, 'Nadaljujte z Google vpisom.')

        const isMatch = await user.verifyPassword(params.password)
        if(!isMatch) throw new ErrorHandler(404, 'Nepravilno geslo.')

        const isConfirmed = user.isConfirmed()
        if(!isConfirmed) throw new ErrorHandler(404, 'E-naslov ni potrjen.')

        const token = await user.generateAuthToken()
        return {
            id: user._id,
            email: params.email,
            token: token,
        }
    }

    const signup = async params => {
        const existingUser = await userModel.findUserBy({
            email: params.email,
        })

        if(existingUser) throw new ErrorHandler(500, 'Uporabnik Å¾e obstaja.')

        const newUser = await userModel.createNewUser(params)

        await sendGrid.sendWelcomeEmail(params.email)

        return {
            email: params.email,
            newUser,
        }
    }

    const verify = async (email) => {
        const user = await userModel.findUserByEmail(email)
        let text = 'RaÄun je Å¾e potrjen!'

        if(user.role === 'UNVERIFIED') {
            text = 'VaÅ¡ raÄun je uspeÅ¡no potrjen!'
            user.role = 'USER'
            user.save()
        }

        return text
    }

    const continueWithGoogle = async idToken => {
        const payload = await google.verifyToken(idToken)
        const sub = payload.sub
        const email = payload.email
        const isVerified = payload.isVerified
        if(!isVerified)
            throw new ErrorHandler(
                404,
                'Gmail raÄun ' +
                email +
                ' ni potrjen. Prosimo uporabite drug raÄun za registracijo.'
            )

        let code = 200
        let user = await userModel.findUserBy({ sub })
        if(!user) {
            user = await userModel.createNewUser({ email, sub, role: 'USER' })
            code = 201
        }
        const id = user._id

        return {
            code,
            id,
            email,
            token: await user.generateAuthToken(),
        }
    }

    const continueWithFacebook = async accessToken => {
        const [debugResponse, emailResponse] = await facebook.verifyToken(accessToken)
        if(debugResponse.status !== 200)
            throw new ErrorHandler(401, 'Unauthenticated.')
        if(emailResponse.status !== 200)
            throw new ErrorHandler(404, 'There is no email associated with this Facebook account.')

        const email = emailResponse.data.email
        const fid = emailResponse.data.id

        let code = 200
        let user = await userModel.findUserBy({ fid })
        if(!user) {
            user = await userModel.createNewUser({ email, fid, role: 'USER' })
            code = 201
        }
        const id = user._id

        return {
            code,
            id,
            email,
            token: await user.generateAuthToken(),
        }
    }

    const deleteAccount = async (userId) => {
        await sosModel.deleteAllFor({ owner: userId })
        //todo -> delete all user's posts as wel
        return userModel.delete(userId)
    }

    const getPetsForUser = (userId) => sosModel.findAllFor({ owner: userId })

    return {
        login,
        signup,
        verify,
        continueWithGoogle,
        continueWithFacebook,
        deleteAccount,
        getPetsForUser,
    }
}

module.exports = UserService